package W3C::SOAP::WSDL::Parser;

# Created on: 2012-05-27 18:58:29
# Create by:  Ivan Wills
# $Id$
# $Revision$, $HeadURL$, $Date$
# $Revision$, $Source$, $Date$

use Moose;
use warnings;
use version;
use Carp;
use Scalar::Util;
use List::Util;
#use List::MoreUtils;
use Data::Dumper qw/Dumper/;
use English qw/ -no_match_vars /;
use Path::Class;
use W3C::SOAP::XSD::Parser;
use W3C::SOAP::WSDL::Document;
use W3C::SOAP::WSDL::Meta::Method;
use File::ShareDir qw/dist_dir/;

Moose::Exporter->setup_import_methods(
    as_is => ['load_wsdl'],
);

our $VERSION     = version->new('0.0.4');

has document => (
    is       => 'rw',
    isa      => 'W3C::SOAP::WSDL::Document',
    required => 1,
    handles  => {
        module          => 'module',
        has_module      => 'has_module',
        ns_module_map   => 'ns_module_map',
        module_base     => 'module_base',
        has_module_base => 'has_module_base',
    },
);
has template => (
    is        => 'rw',
    isa       => 'Template',
    predicate => 'has_template',
);
has location => (
    is  => 'rw',
    isa => 'Str',
);
has lib => (
    is        => 'rw',
    isa       => 'Str',
    predicate => 'has_lib',
);

around BUILDARGS => sub {
    my ($orig, $class, @args) = @_;
    my $args
        = !@args     ? {}
        : @args == 1 ? $args[0]
        :              {@args};

    for my $arg ( keys %$args ) {
        if ( $arg eq 'location' || $arg eq 'string' ) {
            $args->{document} = W3C::SOAP::WSDL::Document->new($args);
        }
    }

    return $class->$orig($args);
};

sub write_modules {
    my ($self) = @_;
    confess "No lib directory setup" if !$self->has_lib;
    confess "No module name setup"   if !$self->has_module;
    confess "No template object set" if !$self->has_template;

    my $wsdl = $self->document;
    my $template = $self->template;
    my $file     = $self->lib . '/' . $self->module . '.pm';
    $file =~ s{::}{/}g;
    $file = file $file;
    my $parent = $file->parent;
    my @missing;
    while ( !-d $parent ) {
        push @missing, $parent;
        $parent = $parent->parent;
    }
    mkdir $_ for reverse @missing;
    my @modules = $self->get_xsd->write_modules;

    confess "No XSD modules found!\n" unless @modules;

    my $data = {
        wsdl     => $wsdl,
        module   => $self->module,
        xsd      => shift @modules,
        modules  => \@modules,
        location => $self->location,
    };
    $template->process('wsdl.pm.tt', $data, "$file");
    confess "Error in creating $file (xsd.pm): ". $template->error."\n"
        if $template->error;

}

sub get_xsd {
    my ($self) = @_;

    my @args;
    push @args, ( template      => $self->template ) if $self->has_template;
    push @args, ( lib           => $self->lib      ) if $self->has_lib     ;
    if ( $self->has_module_base ) {
        my $base = $self->module_base;
        $base =~ s/WSDL/XSD/;
        $base .= '::XSD' if ! $base =~ /XSD/;
        push @args, ( module_base => $base );
    }

    my $parse = W3C::SOAP::XSD::Parser->new(
        documents     => [],
        ns_module_map => $self->ns_module_map,
        @args,
    );

    for my $xsd (@{ $self->document->schemas }) {
        $xsd->ns_module_map($self->ns_module_map);
        $xsd->clear_xpc;

        push @{ $parse->documents }, $xsd;

        $parse->documents->[-1]->target_namespace($self->document->target_namespace)
            if !$parse->documents->[-1]->has_target_namespace;
    }

    return $parse;
}

my %cache;
sub load_wsdl {
    my ($location) = @_;

    return $cache{$location} if $cache{$location};

    my $parser = __PACKAGE__->new(
        location => $location,
        ns_module_map => {},
    );

    my $class = $parser->dynamic_classes;

    return $cache{$location} = $class->new;
}

sub dynamic_classes {
    my ($self) = @_;
    my @classes = $self->get_xsd->dynamic_classes;

    my $ns = $self->document->target_namespace;
    $ns =~ s{://}{::};
    $ns =~ s{([^:]:)([^:])}{$1:$2}g;
    $ns =~ s{[^\w:]+}{_}g;
    my $class_name = "Dynamic::WSDL::$ns";

    my $wsdl = $self->document;
    my %method;
    for my $service (@{ $wsdl->services }) {
        for my $port (@{ $service->ports }) {
            for my $operation (@{ $port->binding->operations }) {
                my $in_element  = eval { $operation->port_type->inputs->[0]->message->element };
                my $out_element = eval { $operation->port_type->outputs->[0]->message->element };

                $method{ $operation->perl_name } = W3C::SOAP::WSDL::Meta::Method->wrap(
                    body           => sub { shift->_request($operation->perl_name => @_) },
                    package_name   => $class_name,
                    name           => $operation->perl_name,
                    wsdl_operation => $operation->name,
                    $in_element  ? ( in_class      => $in_element->module     ) : (),
                    $in_element  ? ( in_attribute  => $in_element->perl_name  ) : (),
                    $out_element ? ( out_class     => $out_element->module    ) : (),
                    $out_element ? ( out_attribute => $out_element->perl_name ) : (),
                );
            }
        }
    }

    my $class = Moose::Meta::Class->create(
        $class_name,
        superclasses => [ 'W3C::SOAP::WSDL' ],
        methods      => \%method,
    );

    $class->add_attribute(
        '+location',
        default  => $wsdl->services->[0]->ports->[0]->address,
        required => 1,
    );

    return $class_name;
}

1;

__END__

=head1 NAME

W3C::SOAP::WSDL::Parser - Module to create Moose objects from a WSDL

=head1 VERSION

This documentation refers to W3C::SOAP::WSDL::Parser version 0.0.4.

=head1 SYNOPSIS

   use W3C::SOAP::WSDL::Parser qw/load_wsdl?;

   # quick/simple usage
   # create a SOAP client
   $url = 'http://example.com/soap.wsdl';
   my $client = load_wsdl($url);
   my $result = $client->some_action(...);

   # Create a new object
   my $wsdl = W3C::SOAP::WSDL::Parser->new(
       location => $url,
       module   => 'MyApp::WSDL',
       lib      => './lib',
       template => Template->new(...),
       ns_module_map => {
           'http://example.com/xsd/namespace' => 'MyAPP::XSD::Example',
           'some.other.namespace'             => 'MyApp::XSD::SomeOther',
       },
   );

   # Write the generated WSDL module to disk
   $wsdl->write_modules();
   # would generate files
   #   lib/MyApp/WSDL.pm
   #   lib/MyApp/XSD/Example.pm
   #   lib/MyApp/XSD/SomeOther.pm

=head1 DESCRIPTION

This module parses a WSDL file so that it can produce a client to talk to the
SOAP service.

=head1 SUBROUTINES/METHODS

=head2 EXPORTED SUBROUTINES

=over 4

=item C<load_wsdl ($location)>

Helper method that takes the supplied location and creates the dynamic WSDL
client object.

=back

=head2 CLASS METHODS

=over 4

=item C<new (%args)>

Create the new object C<new> accepts the following arguments:

=over 4

=item location

This is the location of the WSDL file, it may be a local file or a URL

=item module

This is the name of the module to be generated, it is required when writing
the SOAP client to disk, the dynamic client generator creates a semi random
namespace.

=item lib

The library directory where modules should be stored. only required when
calling C<write_modules>

=item template

The Template Toolkit object used for the generation of on disk modules

=item ns_module_map

The mapping of XSD namespaces to perl Modules.

=back

=back

=head2 OBJECT METHODS

=over 4

=item C<$wsdl->write_modules ()>

Writes out a module that is a SOAP Client to interface with the contained
WSDL document, also writes any referenced XSDs.

=item C<$wsdl->dynamic_classes ()>

Creates a dynamic SOAP client object to talk to the WSDL this object was
created for

=item C<$wsdl->get_xsd ()>

Creates the L<W3C::SOAP::XSD::Parser> object that represents the XSDs that
are used by the specified WSDL file.

=back

=head1 DIAGNOSTICS

=head1 CONFIGURATION AND ENVIRONMENT

=head1 DEPENDENCIES

=head1 INCOMPATIBILITIES

=head1 BUGS AND LIMITATIONS

There are no known bugs in this module.

Please report problems to Ivan Wills (ivan.wills@gmail.com).

Patches are welcome.

=head1 AUTHOR

Ivan Wills - (ivan.wills@gmail.com)

=head1 LICENSE AND COPYRIGHT

Copyright (c) 2012 Ivan Wills (14 Mullion Close, Hornsby Heights, NSW Australia 2077).
All rights reserved.

This module is free software; you can redistribute it and/or modify it under
the same terms as Perl itself. See L<perlartistic>.  This program is
distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY;
without even the implied warranty of MERCHANTABILITY or FITNESS FOR A
PARTICULAR PURPOSE.

=cut

package W3C::SOAP::WSDL::Parser;

# Created on: 2012-05-27 18:58:29
# Create by:  Ivan Wills
# $Id$
# $Revision$, $HeadURL$, $Date$
# $Revision$, $Source$, $Date$

use Moose;
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
use File::ShareDir qw/dist_dir/;


our $VERSION     = version->new('0.0.1');
our @EXPORT_OK   = qw/load_wsdl/;
our %EXPORT_TAGS = ();
#our @EXPORT      = qw//;

has document => (
    is       => 'rw',
    isa      => 'W3C::SOAP::WSDL::Document',
    required => 1,
);
has template => (
    is       => 'rw',
    isa      => 'Template',
    required => 1,
);
has ns_module_map => (
    is       => 'rw',
    isa      => 'HashRef[Str]',
    required => 1,
);
has module => (
    is       => 'rw',
    isa      => 'Str',
    required => 1,
);
has location => (
    is       => 'rw',
    isa      => 'Str',
);
has lib => (
    is       => 'rw',
    isa      => 'Str',
    required => 1,
);

around BUILDARGS => sub {
    my ($orig, $class, @args) = @_;
    my $args
        = !@args     ? {}
        : @args == 1 ? $args[0]
        :              {@args};

    for my $arg ( keys %$args ) {
        if ( $arg eq 'location' || $arg eq 'strign' ) {
            $args->{document} = W3C::SOAP::WSDL::Document->new($args);
        }
    }

    return $class->$orig($args);
};

sub write_modules {
    my ($self) = @_;
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
    die "Error in creating $file (xsd.pm): ". $template->error."\n"
        if $template->error;

}

sub get_xsd {
    my ($self, ) = @_;

    my $parse = W3C::SOAP::XSD::Parser->new(
        documents     => [],
        template      => $self->template,
        lib           => $self->lib     ,
        ns_module_map => $self->ns_module_map,
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

sub load_wsdl {
    my ($location) = @_;
    my $parser = __PACKAGE__->new(
        location => $location,
        ns_module_map => {},
    );

    return $parser->dynamic_classes;
}

sub dynamic_classes {
    my ($self) = @_;
    my @classes = $self->get_xsd->dynamic_classes;

    my $ns = $self->document->target_namespace;
    $ns =~ s{://}{::};
    $ns =~ s{([^:]:)([^:])}{$1:$2}g;
    $ns =~ s{[^\w:]+}{_}g;
    my $class_name = "Dynamic::XSD::$ns";
    $self->ns_module_map->{$self->document->target_namespace}
        = $class_name;

    my $class = Moose::Meta::Class->create(
        $class_name,
        superclasses => [ 'W3C::SOAP::WSDL' ],
    );

    $class->add_attribute(
        '+location',
        default  => $self->document->target_namespace,
        required => 1,
    );

    my $wsdl = $self->document;
    for my $service ( $wsdl->services ) {
        for my $port ( $service->ports ) {
            for my $operation ( $port->binding->operations ) {
                my $in_element  = eval { $operation->port_type->inputs->[0]->message->element };
                my $out_element = eval { $operation->port_type->outputs->[0]->message->element };
                my $in_module  = $in_element->module  if $in_element;
                my $out_module = $out_element->module if $out_element;
                my $in_name  = $in_element->name  if $in_element;
                my $out_name = $out_element->name if $out_element;

                #"".$operation->perl_name =
                sub {
                    my $self = shift;

                   if ( $operation->port_type->outputs->[0]->message->element ) {

                        my $xsd = $in_module->new(
                            $in_name => @_ == 1 ? $_[0] : {@_},
                        );
                        my $resp = $self->request( $operation->name => $xsd );

                        return $out_module->new($resp)->$out_name;

                   }
                   elsif ( $operation->port_type->inputs->[0]->message->element ) {

                        my $xsd = $in_module->new(
                            $in_name => @_ == 1 ? $_[0] : {@_},
                        );
                        my $resp = $self->request( $operation->name > $xsd );

                        return $resp;

                    }
                    elsif ( $operation->port_type->outputs->[0]->message->type ) {
                        #$type = $operation->port_type->outputs->[0]->message->type

                        #return $resp->firstChild->toString;
                    }
                }
#[%- if ( config->alias && element->name->replace('^\w+:', '') != element->perl_name %]
#alias [% element->name->replace('^\w+:', '') %] => '[% element->perl_name %]';
#[%- END %]
            }
        }
    }

}

1;

__END__

=head1 NAME

W3C::SOAP::WSDL::Parser - Module to create Moose objects from a WSDL

=head1 VERSION

This documentation refers to W3C::SOAP::WSDL::Parser version 0.1.

=head1 SYNOPSIS

   use W3C::SOAP::WSDL::Parser;

   # Brief but working code example(s) here showing the most common usage(s)
   # This section will be as far as many users bother reading, so make it as
   # educational and exemplary as possible.


=head1 DESCRIPTION

A full description of the module and its features.

May include numerous subsections (i.e., =head2, =head3, etc.).


=head1 SUBROUTINES/METHODS

=over 4

=item C<write_modules ()>

Writes out a module that is a SOAP Client to interface with the contained
WSDL document, also writes any referenced XSDs.

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

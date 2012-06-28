package W3C::SOAP::XSD::Parser;

# Created on: 2012-05-28 08:11:37
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
use W3C::SOAP::XSD::Document;
use File::ShareDir qw/dist_dir/;
use Moose::Util::TypeConstraints;

our $VERSION     = version->new('0.0.1');
our @EXPORT_OK   = qw/load_xsd/;
our %EXPORT_TAGS = ();
#our @EXPORT      = qw//;

subtype xsd_documents =>
    as 'ArrayRef[W3C::SOAP::XSD::Document]';
coerce xsd_documents =>
    from 'W3C::SOAP::XSD::Document',
    via {[$_]};
has documents => (
    is       => 'rw',
    isa      => 'xsd_documents',
    coerce   => 1,
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
        if ( $arg eq 'location' || $arg eq 'string' ) {
            $args->{documents} = W3C::SOAP::XSD::Document->new($args);
        }
    }

    return $class->$orig($args);
};

sub write_modules {
    my ($self) = @_;
    my @xsds     = $self->get_schemas;
    my $template = $self->template;
    my @schemas;
    my $self_module;
    my @parents;
    my @xsd_modules;

    # process the schemas
    for my $xsd (@xsds) {
        my $module = $xsd->get_module_base($xsd->target_namespace);
        push @xsd_modules, $module;
        $self_module ||= $module;
        my $file   = $self->lib . '/' . $module;
        $file =~ s{::}{/}g;
        $file = file $file;
        my $parent = $file->parent;
        my @missing;
        while ( !-d $parent ) {
            push @missing, $parent;
            $parent = $parent->parent;
        }
        mkdir $_ for reverse @missing;

        for my $type ( @{ $xsd->complex_types } ) {
            my $type_name = $type->name || $type->parent_node->name;
            warn  "me          = ".(ref $type).
                "\nnode        = ".($type->node->nodeName).
                "\nparent      = ".(ref $type->parent_node).
                "\nparent node = ".($type->node->parentNode->nodeName).
                "\ndocument    = ".(ref $type->document)."\n"
                if !$type_name;
            confess "No name found for ",
                $type->node->toString,
                "\nin :\n",
                $type->document->string,"\n"
                if !$type_name;
            my $type_module = $module . '::' . $type_name;
            push @parents, $type_module;
            my $type_file = $self->lib . '/' . $type_module;
            $type_file =~ s{::}{/}g;
            $type_file = file $type_file;
            mkdir $type_file->parent if !-d $type_file->parent;

            my %modules;
            for my $el (@{ $type->sequence }) {
                $modules{ $el->type_module }++
                    if ! $el->simple_type && $el->module ne $module
            }

            # write the complex type module
            $self->write_module(
                'xsd_complex_type.pm.tt',
                {
                    xsd     => $xsd,
                    module  => $type_module,
                    modules => [ keys %modules ],
                    node    => $type
                },
                "$type_file.pm"
            );
        }

        # write the simple types library
        $self->write_module(
            'xsd_base.pm.tt',
            {
                xsd => $xsd,
            },
            "$file/Base.pm"
        );

        # write the "XSD" elements module
        $self->write_module(
            'xsd.pm.tt',
            {
                xsd => $xsd,
                parents => \@parents,
            },
            "$file.pm"
        );

    }

    #warn Dumper \@xsd_modules, $self_module;
    return $self_module;
}

my %written;
sub write_module {
    my ($self, $tt, $data, $file) = @_;
    my $template = $self->template;
    confess "Already written $file!\n" if $written{$file}++;

    $template->process($tt, $data, "$file");
    die "Error in creating $file (via $tt): ". $template->error."\n"
        if $template->error;
}

sub get_schemas {
    my ($self) = @_;
    my @xsds   = @{ $self->documents };
    my %xsd;

    # import all schemas
    while ( my $xsd = shift @xsds ) {
        my $target_namespace = $xsd->target_namespace;
        push @{ $xsd{$target_namespace} }, $xsd;

        for my $import ( @{ $xsd->imports } ) {
            push @xsds, $import;
        }
        for my $include ( @{ $xsd->includes } ) {
            push @xsds, $include;
        }
    }

    # flatten schemas specified more than once
    for my $ns ( keys %xsd ) {
        my $xsd = pop @{ $xsd{$ns} };
        if ( @{ $xsd{$ns} } ) {
            for my $xsd_repeat ( @{ $xsd{$ns} } ) {
                push @{ $xsd->simple_types  }, @{ $xsd_repeat->simple_types  };
                push @{ $xsd->complex_types }, @{ $xsd_repeat->complex_types };
                push @{ $xsd->elements      }, @{ $xsd_repeat->elements      };
            }
        }

        push @xsds, $xsd;
    }

    return @xsds;
}

sub load_xsd {
    my ($location) = @_;
    my $parser = __PACKAGE__->new(
        location      => $location,
        ns_module_map => {},
    );

    return $parser->dynamic_classes;
}

sub dynamic_classes {
    my ($self) = @_;
    my @xsds   = $self->get_schemas;
    my @packages;

    # construct the in memory module names
    for my $xsd (@xsds) {
        my $ns = $xsd->target_namespace;
        $ns =~ s{://}{::};
        $ns =~ s{([^:]:)([^:])}{$1:$2}g;
        $ns =~ s{[^\w:]+}{_}g;
        $self->ns_module_map->{$xsd->target_namespace}
            = "Dynamic::XSD::$ns";
    }

    for my $xsd (@xsds) {
        my $module = $xsd->get_module_base($xsd->target_namespace);

        # Create simple types
        $self->simple_type_package($xsd);

        # Complex types
        for my $type ( @{ $xsd->complex_types } ) {
            my $type_name = $type->name || $type->parent_node->name;
            my $type_module = $module . '::' . $type_name;

            my %modules = ( 'W3C::SOAP::XSD' => 1 );
            for my $el (@{ $type->sequence }) {
                $modules{ $el->type_module }++
                    if ! $el->simple_type && $el->module ne $module
            }

            $self->complex_type_package($xsd, $type, $type_module, [ keys %modules ]);
        }

        # elements package
        $self->elements_package($xsd, $module);

        push @packages, $module;
    }

    return @packages;
}

sub simple_type_package {
    my ($self, $xsd) = @_;

    for my $subtype (@{ $xsd->simple_types }) {
        next if !$subtype->name;

        # Setup base simple types
        if ( @{ $subtype->enumeration } ) {
            enum(
                $subtype->moose_type
                => $subtype->enumeration
            );
        }
        else {
            subtype $subtype->moose_type =>
                as $subtype->moose_base_type;
        }

        # Add coercion from XML::LibXML nodes
        coerce $subtype->moose_type =>
            from 'xml_node' =>
            via { $_->textContent };
    }

    return;
}

sub complex_type_package {
    my ($self, $xsd, $type, $class_name, $super) = @_;

    my $class = Moose::Meta::Class->create(
        $class_name,
        superclasses => $super,
    );

    for my $node (@{ $type->sequence }) {
        $self->element_attributes($class, $class_name, $node);
    }

    return $class;
}

sub elements_package {
    my ($self, $xsd, $class_name) = @_;

    my $class = Moose::Meta::Class->create(
        $class_name,
        superclasses => [ 'W3C::SOAP::XSD' ],
    );

    $class->add_attribute(
        '+xsd_ns',
        default  => $xsd->target_namespace,
        required => 1,
    );

    for my $node (@{ $xsd->elements }) {
        $self->element_attributes($class, $class_name, $node);
    }

    return $class;
}

sub element_attributes {
    my ($self, $class, $class_name, $element) = @_;

    my $simple = $element->simple_type;
    my $very_simple = $element->very_simple_type;
    my $is_array = $element->max_occurs eq 'unbounded'
        || ( $element->max_occurs && $element->max_occurs > 1 )
        || ( $element->min_occurs && $element->min_occurs > 1 );
    my $type_name = $simple || $element->type_module;
    my $searalize = '';

    if ( $very_simple ) {
        warn "Very simple type $very_simple\n";
        if ( $very_simple eq 'xs:boolean' ) {
            $searalize = sub { $_ ? 'true' : 'false' };
        }
        elsif ( $very_simple eq 'xs:date' ) {
            $searalize = sub {
                return $_->ymd if $_->time_zone->isa('DateTime::TimeZone::Floating');
                my $d = DateTime::Format::Strptime::strftime('%F%z', $_);
                $d =~ s/([+-]\\d\\d)(\\d\\d)\$/\$1:\$2/;
                return $d
            };
        }
        elsif ( $very_simple eq 'xs:time' ) {
            $searalize = sub { $_->hms };
        }
    }

    my @extra;
    push @extra, ( xs_perl_module  => $element->type_module  ) if !$simple;
    push @extra, ( xs_choice_group => $element->choice_group ) if $element->choice_group;
    push @extra, ( xs_searalize    => $searalize             ) if $searalize;

    $class->add_attribute(
        $element->perl_name,
        is            => 'rw',
        isa           => $class_name->xsd_subtype(
            ($simple ? 'parent' : 'module') => $type_name,
           list => $is_array,
        ),
        predicate     => 'has_'. $element->perl_name,
        required      => 0, # TODO $element->nillable,
        coerce        => 1,
    #[%- IF config->alias && element->name.replace('^\w+:', '') != element->perl_name %]
        #alias         => '[% element->name.replace('^\w+:', '') %]',
    #[%- END %]
        traits        => [qw{ W3C::SOAP::XSD }],
        xs_name       => $element->name,
        xs_type       => $element->type,
        xs_min_occurs => $element->min_occurs,
        xs_max_occurs => $element->max_occurs  eq 'unbounded' ? 0 : $element->max_occurs,
    );
}
1;

__END__

=head1 NAME

W3C::SOAP::XSD::Parser - Parse an W3C::SOAP::XSD::Document and reate perl modules

=head1 VERSION

This documentation refers to W3C::SOAP::XSD::Parser version 0.1.

=head1 SYNOPSIS

   use W3C::SOAP::XSD::Parser;

   # Brief but working code example(s) here showing the most common usage(s)
   # This section will be as far as many users bother reading, so make it as
   # educational and exemplary as possible.


=head1 DESCRIPTION

=head1 SUBROUTINES/METHODS

=over 4

=item C<load_xsd ($schema_location)>

Loads the schema and dynamically generates the Perl/Moose packages that
represent the schema.

=item C<write_modules ()>

Uses the supplied documents to write out perl modules to disk that represent
the XSDs in the documents.

=item C<write_module ($tt, $data, $file)>

Write the template to disk

=item C<get_schemas ()>

Gets a list of the schemas imported/included from the base XML Schema(s)

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

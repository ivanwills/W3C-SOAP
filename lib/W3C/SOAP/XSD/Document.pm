package W3C::SOAP::XSD::Document;

# Created on: 2012-05-26 15:46:31
# Create by:  Ivan Wills
# $Id$
# $Revision$, $HeadURL$, $Date$
# $Revision$, $Source$, $Date$

use Moose;
use version;
use Carp qw/carp croak cluck confess longmess/;
use Scalar::Util;
use List::Util;
#use List::MoreUtils;
use Data::Dumper qw/Dumper/;
use English qw/ -no_match_vars /;
use Path::Class;
use XML::LibXML;
use WWW::Mechanize;
use TryCatch;
use W3C::SOAP::XSD::Document::Element;
use W3C::SOAP::XSD::Document::ComplexType;
use W3C::SOAP::XSD::Document::SimpleType;

extends 'W3C::SOAP::Document';

our $VERSION     = version->new('0.0.1');
our @EXPORT_OK   = qw//;
our %EXPORT_TAGS = ();
#our @EXPORT      = qw//;

has imports => (
    is         => 'rw',
    isa        => 'ArrayRef[W3C::SOAP::XSD::Document]',
    builder    => '_imports',
    lazy_build => 1,
);
has imported => (
    is         => 'rw',
    isa        => 'HashRef[W3C::SOAP::XSD::Document]',
    builder    => '_imported',
    lazy_build => 1,
);
has includes => (
    is         => 'rw',
    isa        => 'ArrayRef[W3C::SOAP::XSD::Document]',
    builder    => '_includes',
    lazy_build => 1,
);
has include => (
    is         => 'rw',
    isa        => 'HashRef[W3C::SOAP::XSD::Document]',
    builder    => '_include',
    lazy_build => 1,
);
has simple_types => (
    is         => 'rw',
    isa        => 'ArrayRef[W3C::SOAP::XSD::Document::SimpleType]',
    builder    => '_simple_types',
    lazy_build => 1,
);
has simple_type => (
    is         => 'rw',
    isa        => 'HashRef[W3C::SOAP::XSD::Document::SimpleType]',
    builder    => '_simple_type',
    lazy_build => 0,
);
has complex_types => (
    is         => 'rw',
    isa        => 'ArrayRef[W3C::SOAP::XSD::Document::ComplexType]',
    builder    => '_complex_types',
    lazy_build => 1,
);
has complex_type => (
    is         => 'rw',
    isa        => 'HashRef[W3C::SOAP::XSD::Document::ComplexType]',
    builder    => '_complex_type',
    lazy_build => 0,
);
has elements => (
    is         => 'rw',
    isa        => 'ArrayRef[W3C::SOAP::XSD::Document::Element]',
    builder   => '_elements',
    lazy_build => 1,
);
has element => (
    is         => 'rw',
    isa        => 'HashRef[W3C::SOAP::XSD::Document::Element]',
    builder   => '_element',
    lazy_build => 1,
);
has module => (
    is        => 'rw',
    isa       => 'Str',
    builder   => '_module',
    lazy_build => 1,
);
has ns_map => (
    is         => 'rw',
    isa        => 'HashRef[Str]',
    predicate  => 'has_ns_map',
    builder    => '_ns_map',
    lazy_build => 1,
);
has ns_module_map => (
    is        => 'rw',
    isa       => 'HashRef[Str]',
    #default   => sub {{}},
    required  => 1,
    predicate => 'has_ns_module_map',
);

sub _imports {
    my ($self) = @_;
    my @imports;
    my @nodes = $self->xpc->findnodes('//xsd:import');

    for my $import (@nodes) {
        my $location = $import->getAttribute('schemaLocation');
        push @imports, __PACKAGE__->new( location => $location, ns_module_map => $self->ns_module_map );
    }

    return \@imports;
}

sub _imported {
    my ($self) = @_;
    my %import;
    for my $import (@{ $self->imports }) {
        $import{$import->name} = $import;
    }
    return \%import;
}

sub _includes {
    my ($self) = @_;
    my @includes;
    my @nodes = $self->xpc->findnodes('//xsd:include');

    for my $include (@nodes) {
        my $location = $include->getAttribute('schemaLocation');
        push @includes, __PACKAGE__->new( location => $location, ns_module_map => $self->ns_module_map );
    }

    return \@includes;
}

sub _include {
    my ($self) = @_;
    my %include;
    for my $include (@{ $self->include }) {
        $include{$include->name} = $include;
    }
    return \%include;
}

sub _simple_types {
    my ($self) = @_;
    my @simple_types;
    my @nodes = $self->xpc->findnodes('//xsd:simpleType');

    for my $node (@nodes) {
        push @simple_types, W3C::SOAP::XSD::Document::SimpleType->new(
            document => $self,
            node   => $node,
        );
    }

    return \@simple_types;
}

my $simple_type_count = 0;
sub _simple_type {
    my ($self) = @_;
    my %simple_type;

    for my $type (@{ $self->simple_types }) {
        my $name = $type->name;
        if ( !$name ) {
            my $parent = $type->node->parentNode;
            $name = $parent->getAttribute('name');
            $name = $name ? 'anon'.$simple_type_count++ : $name;
            $type->name($name);
        }
        die "No name for simple type ".$type->node->parentNode->toString if !$name;
        $simple_type{$name} = $type;
    }
    #warn "created: $self\n\t", join "\t", sort keys %simple_type;

    return \%simple_type;
}

sub _complex_types {
    my ($self) = @_;
    my @complex_types;
    my @nodes = $self->xpc->findnodes('//xsd:complexType');

    for my $node (@nodes) {
        my $parent = $node->parentNode;
        if ( $parent->nodeName !~ /\bschema$/ ) {
            if ( $parent->nodeName =~ /\belement/ ) {
                for my $element (@{ $self->elements }) {
                    if ( $parent->getAttribute('name') eq $element->name ) {
                        $parent = $element;
                        last;
                    }
                }
            }
            else {
                warn "?????? ". $parent->nodeName;
            }
        }
        else {
            $parent = undef;
        }

        try {
            push @complex_types, W3C::SOAP::XSD::Document::ComplexType->new(
                ($parent ? (parent_node => $parent) : ()),
                document => $self,
                node     => $node,
            );
        }
        catch ($e) {
            warn Dumper {
                ($parent ? (parent_node => $parent) : ()),
                document => $self,
                node     => $node,
            };
            die $e;
        }
    }

    return \@complex_types;
}

my $complex_type_count = 0;
sub _complex_type {
    my ($self) = @_;
    my %complex_type;
    for my $type (@{ $self->complex_types }) {
        my $name = $type->name;
        if ( !$name ) {
            my $parent = $type->node->parentNode;
            $name = $parent->getAttribute('name');
            $name = $name ? 'Anon'.$complex_type_count++ : $name;
            $type->name($name);
        }
        die "No name for complex type ".$type->node->parentNode->toString if !$name;
        $complex_type{$name} = $type;
    }

    return \%complex_type;
}

sub _elements {
    my ($self) = @_;
    my @elements;
    my @nodes = $self->xpc->findnodes('/*/xsd:element');

    for my $node (@nodes) {
        push @elements, W3C::SOAP::XSD::Document::Element->new(
            document => $self,
            node   => $node,
        );
    }

    return \@elements;
}

sub _element {
    my ($self) = @_;
    my %element;
    for my $element (@{ $self->element }) {
        $element{$element->name} = $element;
    }
    return \%element;
}

sub _module {
    my ($self) = @_;

    die "Trying to get module mappings when none specified!\n" if !$self->has_ns_module_map;
    die "No mapping specified for the namespace ", $self->target_namespace, "!\n" if !$self->ns_module_map->{$self->target_namespace};

    return $self->ns_module_map->{$self->target_namespace};
}

sub _ns_map {
    my ($self) = @_;

    my %map
        = map {$_->name =~ /^xmlns:?(.*)$/; ($1 => $_->value)}
        grep { $_->name =~ /^xmlns/ }
        $self->xml->firstChild->getAttributes;

    return \%map;
}

sub get_ns_uri {
    my ($self, $ns_name) = @_;
    confess "No namespace passed when trying to map a namespace uri!\n" if !defined $ns_name;
    confess "Couldn't find the namespace '$ns_name' to map\nMap has:\n", Dumper $self->ns_map if !$self->ns_map->{$ns_name};

    return $self->ns_map->{$ns_name};
}

sub get_module_base {
    my ($self, $ns) = @_;

    die "Trying to get module mappings when none specified!\n" if !$self->has_ns_module_map;
    die "No mapping specified for the namespace $ns!\n"        if !$self->ns_module_map->{$ns};

    return $self->ns_module_map->{$ns};
}

1;

__END__

=head1 NAME

W3C::SOAP::XSD::Document - Represents a XMLSchema Document

=head1 VERSION

This documentation refers to W3C::SOAP::XSD::Document version 0.1.

=head1 SYNOPSIS

   use W3C::SOAP::XSD::Document;

   my $xsd = W3C::SOAP::XSD::Document->new(
        location => 'my.xsd',
        ns_base => {
            'http://xml.namespace.com/SomeTing.html' => 'MyApp::SomeTing',
        },
   );

=head1 DESCRIPTION

Takes a XMLSchema Document and makes the contents available in a convienient
interface.

=head1 SUBROUTINES/METHODS

=head1 DIAGNOSTICS

=head1 CONFIGURATION AND ENVIRONMENT

=head1 DEPENDENCIES

=head1 INCOMPATIBILITIES

=head1 BUGS AND LIMITATIONS

Please report problems to Ivan Wills (ivan.wills@gmail.com).

Patches are welcome.

=head1 AUTHOR

Ivan Wills - (ivan.wills@gmail.com)

=head1 LICENSE AND COPYRIGHT

Copyright (c) 2012 Ivan Wills (14 Mullion Close Hornsby Heights NSW Australia).
All rights reserved.

This module is free software; you can redistribute it and/or modify it under
the same terms as Perl itself. See L<perlartistic>.  This program is
distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY;
without even the implied warranty of MERCHANTABILITY or FITNESS FOR A
PARTICULAR PURPOSE.

=cut

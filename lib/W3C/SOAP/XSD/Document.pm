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
    lazy_build => 1,
);
has complex_types => (
    is         => 'rw',
    isa        => 'ArrayRef[W3C::SOAP::XSD::Document::ComplexType]',
    builder    => '_complex_types',
    lazy_build => 1,
);
has elements => (
    is         => 'rw',
    isa        => 'ArrayRef[W3C::SOAP::XSD::Document::Element]',
    builder   => '_elements',
    lazy_build => 1,
);
has module => (
    is        => 'rw',
    isa       => 'Str',
    builder   => '_module',
    lazy_build => 1,
);
has ns_map => (
    is        => 'rw',
    isa       => 'HashRef[Str]',
    predicate => 'has_ns_map',
);
has ns_module_map => (
    is        => 'rw',
    isa       => 'HashRef[Str]',
    default   => sub {{}},
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

    @nodes = $self->xpc->findnodes('//xsd:include');

    for my $import (@nodes) {
        my $location = $import->getAttribute('schemaLocation');
        push @imports, __PACKAGE__->new( location => $location, ns_module_map => $self->ns_module_map );
    }

    return \@imports;
}

sub _simple_types {
    my ($self) = @_;
    my @simple_types;
    my @nodes = $self->xpc->findnodes('//xsd:simpleType');

    for my $node (@nodes) {
        push @simple_types, W3C::SOAP::XSD::Document::SimpleType->new(
            parent => $self,
            node   => $node,
        );
    }

    return \@simple_types;
}

sub _simple_type {
    my ($self) = @_;
    my %simple_type;

    for my $type (@{ $self->simple_types }) {
        $simple_type{$type->name} = $type;
    }

    return \%simple_type;
}

sub _complex_types {
    my ($self) = @_;
    my @complex_types;
    my @nodes = $self->xpc->findnodes('//xsd:complexType');

    for my $node (@nodes) {
        push @complex_types, W3C::SOAP::XSD::Document::ComplexType->new(
            parent => $self,
            node   => $node,
        );
    }

    return \@complex_types;
}

sub _elements {
    my ($self) = @_;
    my @elements;
    my @nodes = $self->xpc->findnodes('/*/xsd:element');

    for my $node (@nodes) {
        push @elements, W3C::SOAP::XSD::Document::Element->new(
            parent => $self,
            node   => $node,
        );
    }

    return \@elements;
}

sub _module {
    my ($self) = @_;

    die "Trying to get module mappings when none specified!\n" if !$self->has_ns_module_map;
    die "No mapping specified for the namespace ", $self->target_namespace, "!\n" if !$self->ns_module_map->{$self->target_namespace};

    return $self->ns_module_map->{$self->target_namespace};
}

sub get_ns_uri {
    my ($self, $ns_name) = @_;
    confess "No namespace passed when trying to map a namespace uri!\n" if !defined $ns_name;

    if ( !$self->has_ns_map ) {
        my %map
            = map {$_->name =~ /^xmlns:?(.*)$/; ($1 => $_->value)}
            grep { $_->name =~ /^xmlns/ }
            $self->xml->firstChild->getAttributes;

        $self->ns_map(\%map);
    }

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

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

our $VERSION     = version->new('0.0.1');
our @EXPORT_OK   = qw//;
our %EXPORT_TAGS = ();
#our @EXPORT      = qw//;

has xml => (
    is       => 'ro',
    isa      => 'XML::LibXML::Document',
    required => 1,
);
has xc => (
    is         => 'ro',
    isa        => 'XML::LibXML::XPathContext',
    builder    => '_xc',
    lazy_build => 1,
);
has target_namespace => (
    is         => 'rw',
    isa        => 'Str',
    builder    => '_target_namespace',
    lazy_build => 1,
);
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

around BUILDARGS => sub {
    my ($orig, $class, @args) = @_;
    my $args
        = !@args     ? {}
        : @args == 1 ? $args[0]
        :              {@args};

    if ( $args->{string} ) {
        $args->{xml} = XML::LibXML->load_xml(string => $args->{string});
    }
    elsif ( $args->{location} ) {
        $args->{xml} = XML::LibXML->load_xml(location => $args->{location});
    }

    return $class->$orig($args);
};

sub _xc {
    my ($self) = @_;
    return XML::LibXML::XPathContext->new($self->xml);
}

sub _target_namespace {
    my ($self) = @_;
    my $ns  = $self->xml->firstChild->getAttribute('targetNamespace');
    my $xc  = $self->xc;
    $xc->registerNs('ns', $ns);
    $xc->registerNs('xsd', 'http://www.w3.org/2001/XMLSchema');

    return $ns;
}

sub _imports {
    my ($self) = @_;
    my @imports;
    my @nodes = $self->xc->findnodes('//xsd:import');

    for my $import (@nodes) {
        my $location = $import->getAttribute('schemaLocation');
        push @imports, __PACKAGE__->new( location => $location, ns_module_map => $self->ns_module_map );
    }

    return \@imports;
}

sub _simple_types {
    my ($self) = @_;
    my @simple_types;
    my @nodes = $self->xc->findnodes('//xsd:simpleType');

    for my $node (@nodes) {
        push @simple_types, W3C::SOAP::XSD::Document::SimpleType->new(
            parent => $self,
            node   => $node,
        );
    }

    return \@simple_types;
}

sub _complex_types {
    my ($self) = @_;
    my @complex_types;
    my @nodes = $self->xc->findnodes('//xsd:complexType');

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
    my @nodes = $self->xc->findnodes('/*/xsd:element');

    for my $node (@nodes) {
        push @elements, W3C::SOAP::XSD::Document::Element->new(
            parent => $self,
            node   => $node,
        );
    }

    return \@elements;
}

sub get_ns_uri {
    my ($self, $ns_name) = @_;

    if ( !$self->has_ns_map ) {
        my %map
            = map {$_->name =~ /^xmlns:(.*)$/; ($1 => $_->value)}
            grep { $_->name =~ /^xmlns:/ }
            $self->xml->firstChild->getAttributes;

        $self->ns_map(\%map);
    }

    confess "Couldn't the namespace $ns_name to map\n" if !$self->ns_map->{$ns_name};
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

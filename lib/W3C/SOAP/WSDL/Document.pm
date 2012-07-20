package W3C::SOAP::WSDL::Document;

# Created on: 2012-05-27 18:57:29
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
use XML::LibXML;
use W3C::SOAP::XSD::Document;
use W3C::SOAP::WSDL::Document::Binding;
use W3C::SOAP::WSDL::Document::Message;
use W3C::SOAP::WSDL::Document::PortType;
use W3C::SOAP::WSDL::Document::Service;

extends 'W3C::SOAP::Document';

our $VERSION     = version->new('0.0.1');

has messages => (
    is         => 'rw',
    isa        => 'ArrayRef[W3C::SOAP::WSDL::Document::Message]',
    builder    => '_messages',
    lazy_build => 1,
);
has message => (
    is         => 'rw',
    isa        => 'HashRef[W3C::SOAP::WSDL::Document::Message]',
    builder    => '_message',
    lazy_build => 1,
    weak_ref   => 1,
);
has port_types => (
    is         => 'rw',
    isa        => 'ArrayRef[W3C::SOAP::WSDL::Document::PortType]',
    builder    => '_port_types',
    lazy_build => 1,
);
has port_type => (
    is         => 'rw',
    isa        => 'HashRef[W3C::SOAP::WSDL::Document::PortType]',
    builder    => '_port_type',
    lazy_build => 1,
    weak_ref   => 1,
);
has bindings => (
    is         => 'rw',
    isa        => 'ArrayRef[W3C::SOAP::WSDL::Document::Binding]',
    builder    => '_bindings',
    lazy_build => 1,
);
has binding => (
    is         => 'rw',
    isa        => 'HashRef[W3C::SOAP::WSDL::Document::Binding]',
    builder    => '_binding',
    lazy_build => 1,
    weak_ref   => 1,
);
has services => (
    is         => 'rw',
    isa        => 'ArrayRef[W3C::SOAP::WSDL::Document::Service]',
    builder    => '_services',
    lazy_build => 1,
);
has service => (
    is         => 'rw',
    isa        => 'HashRef[W3C::SOAP::WSDL::Document::Service]',
    builder    => '_service',
    lazy_build => 1,
    weak_ref   => 1,
);
has policies => (
    is         => 'rw',
    isa        => 'ArrayRef[W3C::SOAP::WSDL::Document::Policy]',
    builder    => '_policies',
    lazy_build => 1,
    weak_ref   => 1,
);
has policy => (
    is         => 'rw',
    isa        => 'HashRef[W3C::SOAP::WSDL::Document::Policy]',
    builder    => '_policy',
    lazy_build => 1,
    weak_ref   => 1,
);
has schemas => (
    is         => 'rw',
    isa        => 'ArrayRef[W3C::SOAP::XSD::Document]',
    builder    => '_schemas',
    lazy_build => 1,
);
has schema => (
    is         => 'rw',
    isa        => 'HashRef[W3C::SOAP::XSD::Document]',
    builder    => '_schema',
    lazy_build => 1,
    weak_ref   => 1,
);
has ns_module_map => (
    is       => 'rw',
    isa      => 'HashRef[Str]',
    required => 1,
);

sub _messages {
    my ($self) = @_;
    my @complex_types;
    my @nodes = $self->xpc->findnodes('//wsdl:message');

    for my $node (@nodes) {
        push @complex_types, W3C::SOAP::WSDL::Document::Message->new(
            document => $self,
            node   => $node,
        );
    }

    return \@complex_types;
}

sub _message {
    my ($self) = @_;
    my %message;
    for my $message ( @{ $self->messages }) {
        $message{$message->name} = $message;
    }

    return \%message;
}

sub _port_types {
    my ($self) = @_;
    my @complex_types;
    my @nodes = $self->xpc->findnodes('//wsdl:portType');

    for my $node (@nodes) {
        push @complex_types, W3C::SOAP::WSDL::Document::PortType->new(
            document => $self,
            node   => $node,
        );
    }

    return \@complex_types;
}

sub _port_type {
    my ($self) = @_;
    my %port_type;
    for my $port_type ( @{ $self->port_type }) {
        $port_type{$port_type->name} = $port_type;
    }

    return \%port_type;
}

sub _bindings {
    my ($self) = @_;
    my @complex_types;
    my @nodes = $self->xpc->findnodes('//wsdl:binding');

    for my $node (@nodes) {
        push @complex_types, W3C::SOAP::WSDL::Document::Binding->new(
            document => $self,
            node   => $node,
        );
    }

    return \@complex_types;
}

sub _binding {
    my ($self) = @_;
    my %binding;
    for my $binding ( @{ $self->binding }) {
        $binding{$binding->name} = $binding;
    }

    return \%binding;
}

sub _services {
    my ($self) = @_;
    my @complex_types;
    my @nodes = $self->xpc->findnodes('//wsdl:service');

    for my $node (@nodes) {
        push @complex_types, W3C::SOAP::WSDL::Document::Service->new(
            document => $self,
            node   => $node,
        );
    }

    return \@complex_types;
}

sub _service {
    my ($self) = @_;
    my %service;
    for my $service ( @{ $self->service }) {
        $service{$service->name} = $service;
    }

    return \%service;
}

sub _policies {
    my ($self) = @_;
    my @complex_types;
    my @nodes = $self->xpc->findnodes('/*/wsp:Policy');

    for my $node (@nodes) {
        push @complex_types, W3C::SOAP::WSDL::Document::Policy->new(
            document => $self,
            node     => $node,
        );
    }

    return \@complex_types;
}

sub _policy {
    my ($self) = @_;
    my %service;
    for my $service ( @{ $self->service }) {
        $service{$service->sec_id} = $service;
    }

    return \%service;
}

sub _schemas {
    my ($self) = @_;
    my @complex_types;
    my @nodes = $self->xpc->findnodes('//wsdl:types/*');

    for my $node (@nodes) {
        push @complex_types, W3C::SOAP::XSD::Document->new(
            string        => $node->toString,
            ns_module_map => $self->ns_module_map ,
        );
    }

    return \@complex_types;
}

sub _schema {
    my ($self) = @_;
    my %schema;
    for my $schema ( @{ $self->schemas }) {
        $schema{$schema->target_namespace} = $schema;
    }

    return \%schema;
}

sub get_nsuri {
    my ($self, $ns) = @_;
    my ($node) = $self->xpc->findnodes("//namespace::*[name()='$ns']");
    return $node->value;
}

sub xsd_modules {
    my ($self) = @_;
    my %modules;

    for my $service (@{ $self->services }) {
        for my $port (@{ $service->ports }) {
            for my $operation (@{ $port->binding->operations }) {
                if ( $operation->port_type->outputs->[0] && $operation->port_type->outputs->[0]->message->element ) {
                    $modules{$operation->port_type->outputs->[0]->message->element->module}++;
                }
            }
        }
    }

    return ( sort keys %modules );
}

1;

__END__

=head1 NAME

W3C::SOAP::WSDL::Document - Object to represent a WSDL Document

=head1 VERSION

This documentation refers to W3C::SOAP::WSDL::Document version 0.1.

=head1 SYNOPSIS

   use W3C::SOAP::WSDL::Document;

   # Brief but working code example(s) here showing the most common usage(s)
   # This section will be as far as many users bother reading, so make it as
   # educational and exemplary as possible.

=head1 DESCRIPTION

Top level look at a WSDL, supplies access to messages, services etc defined
in the WSDL.

=head1 SUBROUTINES/METHODS

=over 4

=item C<get_nsuri ()>

=item C<xsd_modules ()>

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

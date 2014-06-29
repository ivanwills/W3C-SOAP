package W3C::SOAP::WSDL::Document::Operation;

# Created on: 2012-05-28 07:03:06
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
use W3C::SOAP::WSDL::Document::InOutPuts;

extends 'W3C::SOAP::Document::Node';

our $VERSION     = version->new('0.06');

has style => (
    is         => 'rw',
    isa        => 'Str',
    builder    => '_style',
    lazy       => 1,
);
has action => (
    is         => 'rw',
    isa        => 'Str',
    builder    => '_action',
    lazy       => 1,
);
has inputs => (
    is         => 'rw',
    isa        => 'ArrayRef[W3C::SOAP::WSDL::Document::InOutPuts]',
    builder    => '_inputs',
    lazy       => 1,
);
has outputs => (
    is         => 'rw',
    isa        => 'ArrayRef[W3C::SOAP::WSDL::Document::InOutPuts]',
    builder    => '_outputs',
    lazy       => 1,
);
has faults => (
    is         => 'rw',
    isa        => 'ArrayRef[W3C::SOAP::WSDL::Document::InOutPuts]',
    builder    => '_faults',
    lazy       => 1,
);
has port_type => (
    is         => 'rw',
    isa        => 'W3C::SOAP::WSDL::Document::Operation',
    builder    => '_port_type',
    lazy       => 1,
);

sub _style {
    my ($self) = @_;
    my $style = $self->node->getAttribute('style');
    return $style if $style;
    my ($child) = $self->document->xpc->findnode('soap:binding'. $self->node);
    return $child->getAttribute('style');
}

sub _action {
    my ($self) = @_;
    my $action = $self->node->getAttribute('soapAction');
    return $action if $action;
    my ($child) = $self->document->xpc->findnode('soap:binding'. $self->node);
    return $child->getAttribute('soapAction');
}

sub _inputs  { return $_[0]->_in_out_puts('input');  }
sub _outputs { return $_[0]->_in_out_puts('output'); }
sub _faults  { return $_[0]->_in_out_puts('fault');  }
sub _in_out_puts {
    my ($self, $dir) = @_;
    my @puts;
    my @nodes = $self->document->xpc->findnodes("wsdl:$dir", $self->node);

    for my $node (@nodes) {
        push @puts, W3C::SOAP::WSDL::Document::InOutPuts->new(
            parent_node => $self,
            node        => $node,
        );
    }

    return \@puts;
}

sub _port_type {
    my ($self) = @_;
    for my $port_type (@{ $self->document->port_types }) {
        for my $operation (@{ $port_type->operations }) {
            return $operation if $operation->name eq $self->name;
        }
    }

    return;
}

1;

__END__

=head1 NAME

W3C::SOAP::WSDL::Document::Operation - <One-line description of module's purpose>

=head1 VERSION

This documentation refers to W3C::SOAP::WSDL::Document::Operation version 0.06.


=head1 SYNOPSIS

   use W3C::SOAP::WSDL::Document::Operation;

   # Brief but working code example(s) here showing the most common usage(s)
   # This section will be as far as many users bother reading, so make it as
   # educational and exemplary as possible.


=head1 DESCRIPTION

A full description of the module and its features.

May include numerous subsections (i.e., =head2, =head3, etc.).


=head1 SUBROUTINES/METHODS

=over 4

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

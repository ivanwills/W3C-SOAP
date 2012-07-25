package W3C::SOAP::WSDL::Document::Port;

# Created on: 2012-05-27 19:52:35
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
use W3C::SOAP::Utils qw/split_ns/;

extends 'W3C::SOAP::Document::Node';

our $VERSION     = version->new('0.0.2');

has binding => (
    is         => 'rw',
    isa        => 'W3C::SOAP::WSDL::Document::Binding',
    builder    => '_binding',
    lazy_build => 1,
    weak_ref   => 1,
);
has address => (
    is         => 'rw',
    isa        => 'Str',
    builder    => '_address',
    lazy_build => 1,
);

sub _binding {
    my ($self) = @_;
    my ($ns, $name) = split_ns($self->node->getAttribute('binding'));

    for my $binding (@{ $self->document->bindings }) {
        return $binding if $binding->name eq $name;
    }
}

sub _address {
    my ($self) = @_;
    my ($address) = $self->document->xpc->findnodes('soap:address', $self->node);
    return $address->getAttribute('location');
}

1;

__END__

=head1 NAME

W3C::SOAP::WSDL::Document::Port - <One-line description of module's purpose>

=head1 VERSION

This documentation refers to W3C::SOAP::WSDL::Document::Port version 0.0.2.


=head1 SYNOPSIS

   use W3C::SOAP::WSDL::Document::Port;

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

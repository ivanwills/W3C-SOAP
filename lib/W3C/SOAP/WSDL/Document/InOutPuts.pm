package W3C::SOAP::WSDL::Document::InOutPuts;

# Created on: 2012-05-28 07:30:02
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

our $VERSION     = version->new('0.05');

has message => (
    is         => 'rw',
    isa        => 'Maybe[W3C::SOAP::WSDL::Document::Message]',
    builder    => '_message',
);
has policy => (
    is         => 'rw',
    isa        => 'Maybe[Str]',
    builder    => '_policy',
);
has body => (
    is         => 'rw',
    isa        => 'Maybe[Str]',
    builder    => '_body',
);

sub _message {
    my ($self) = @_;
    my ($ns, $message) = split_ns($self->node->getAttribute('message'));

    for my $msg (@{ $self->document->messages }) {
        return $msg if $msg->name eq $message;
    }

    return;
}


1;

__END__

=head1 NAME

W3C::SOAP::WSDL::Document::InOutPuts - <One-line description of module's purpose>

=head1 VERSION

This documentation refers to W3C::SOAP::WSDL::Document::InOutPuts version 0.05.


=head1 SYNOPSIS

   use W3C::SOAP::WSDL::Document::InOutPuts;

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

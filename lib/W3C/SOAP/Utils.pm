package W3C::SOAP::Utils;

# Created on: 2012-06-01 12:15:15
# Create by:  dev
# $Id$
# $Revision$, $HeadURL$, $Date$
# $Revision$, $Source$, $Date$

use strict;
use warnings;
use version;
use Carp;
use Scalar::Util;
use List::Util;
use Data::Dumper qw/Dumper/;
use English qw/ -no_match_vars /;
use base qw/Exporter/;

our $VERSION     = version->new('0.0.1');

sub split_ns {
    my ($tag) = @_;
    confess "No XML tag passed to split!\n" unless defined $tag;
    my ($ns, $name) = split /:/, $tag, 2;
    return $name ? ($ns, $name) : ('', $ns);
}

1;

__END__

=head1 NAME

W3C::SOAP::Utils - Utility functions to be used with C<W3C::SOAP> modules

=head1 VERSION

This documentation refers to W3C::SOAP::Utils version 0.1.

=head1 SYNOPSIS

   use W3C::SOAP::Utils qw/split_ns/;

   # splits tags with an optional XML namespace prefix
   my ($namespace, $tag) = split_ns('xs:thing');
   # $namespace = xs
   # $tag = thing

=head1 DESCRIPTION

Utility Functions

=head1 SUBROUTINES/METHODS

=over 4

=item C<split_ns ($name)>

Splits an XML tag's namespace from the tag name

=back

=head1 DIAGNOSTICS

=head1 CONFIGURATION AND ENVIRONMENT

=head1 DEPENDENCIES

=head1 INCOMPATIBILITIES

=head1 BUGS AND LIMITATIONS

There are no known bugs in this module.

Please report problems to Ivan Wills - (ivan.wills@gmail.com)

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

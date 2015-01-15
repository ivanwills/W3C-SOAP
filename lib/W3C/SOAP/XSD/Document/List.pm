package W3C::SOAP::XSD::Document::List;

# Created on: 2012-05-26 19:04:19
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

extends 'W3C::SOAP::XSD::Document::Type';

our $VERSION     = version->new('0.09');

has type => (
    is         => 'rw',
    isa        => Str,
    builder    => '_type',
    lazy       => 1,
);
has enumeration => (
    is         => 'rw',
    isa        => ArrayRef[Str],
    builder    => '_enumeration',
    lazy       => 1,
);

1;

__END__

=head1 NAME

W3C::SOAP::XSD::Document::List - <One-line description of module's purpose>

=head1 VERSION

This documentation refers to W3C::SOAP::XSD::Document::List version 0.09.


=head1 SYNOPSIS

   use W3C::SOAP::XSD::Document::List;

   # Brief but working code example(s) here showing the most common usage(s)
   # This section will be as far as many users bother reading, so make it as
   # educational and exemplary as possible.


=head1 DESCRIPTION


=head1 SUBROUTINES/METHODS

=over 4

=item C<moose_type ()>

=item C<moose_base_type ()>

=item C<moosex_type ()>

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

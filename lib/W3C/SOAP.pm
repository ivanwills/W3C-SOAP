package W3C::SOAP;

# Created on: 2012-06-29 07:52:54
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
use W3C::SOAP::XSD::Parser qw/load_xsd/;
use W3C::SOAP::WSDL::Parser qw/load_wsdl/;

our $VERSION     = version->new('0.0.1');
our @EXPORT_OK   = qw/load_wsdl load_xsd/;
our %EXPORT_TAGS = ();
#our @EXPORT      = qw//;

1;

__END__

=head1 NAME

W3C::SOAP - SOAP client generation from WSDL & XSD files

=head1 VERSION

This documentation refers to W3C::SOAP version 0.1.

=head1 SYNOPSIS

   use W3C::SOAP qw/load_wsdl/;

   # load some wsdl file
   my $wsdl = load_wsdl("http://example.com/eg.wsdl");

   # call a method exported by the WSDL
   $wsdl->some_method(...);

   # load some xsd file
   my $xsd = load_xsd("http://example.com/eg.xsd");

   # create a new object of of the XSD
   my $obj = $xsd->new( ... );

=head1 DESCRIPTION

=head1 SUBROUTINES/METHODS

=over 4

=item C<load_wsdl ($wsdl_location)>

Loads a WSDL file, parses is and generates dynamic Moose objects that represent
the WSDL file and any XML Schema xsd content that it refers to.

See L<W3C::SOAP::WSDL::Parser> for more details.

=item C<load_xsd ($xsd_location)>

Loads an XML Schema (.xsd) file, parses is and generates dynamic Moose objects
that represening that schema and any other included/imported XML Schema
content that it refers to.

See L<W3C::SOAP::XSD::Parser> for more details.

=back

=head1 DIAGNOSTICS

=head1 CONFIGURATION AND ENVIRONMENT

=head1 DEPENDENCIES

=head1 INCOMPATIBILITIES

=head1 BUGS AND LIMITATIONS

There are no known bugs in this module.

Please report problems to Ivan Wills (ivan.wills@gmail.com).

Patches are welcome.

=head1 ALSO SEE

L<XML::LibXML>, L<MooseX::Types::XMLSchema>

Inspired by L<SOAP::WSDL> & L<SOAP::Lite>

=head1 AUTHOR

Ivan Wills - (ivan.wills@gmail.com)

=head1 LICENSE AND COPYRIGHT

Copyright (c) 2012 Ivan Wills (14 Mullion Close, Hornsby Heights, NSW 2077 Australia).
All rights reserved.

This module is free software; you can redistribute it and/or modify it under
the same terms as Perl itself. See L<perlartistic>.  This program is
distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY;
without even the implied warranty of MERCHANTABILITY or FITNESS FOR A
PARTICULAR PURPOSE.

=cut

package W3C::SOAP;

# Created on: 2012-06-29 07:52:54
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
use W3C::SOAP::XSD::Parser qw/load_xsd/;
use W3C::SOAP::WSDL::Parser qw/load_wsdl/;

Moose::Exporter->setup_import_methods(
    as_is => [qw/load_wsdl load_xsd/],
);

our $VERSION     = version->new('0.0.4');

1;

__END__

=head1 NAME

W3C::SOAP - SOAP client generation from WSDL & XSD files

=head1 VERSION

This documentation refers to W3C::SOAP version 0.0.4.

=head1 SYNOPSIS

   # Dynamically created clients
   use W3C::SOAP qw/load_wsdl/;

   # load some wsdl file
   my $wsdl = load_wsdl("http://example.com/eg.wsdl");

   # call a method exported by the WSDL
   $wsdl->some_method( HASH | HASH_REF );

   # A real world example
   my $wsdl = load_wsdl('http://ws.cdyne.com/ip2geo/ip2geo.asmx?wsdl');
   my $res = $wsdl->resolve_ip( ip_address => '59.106.161.11', license_key => 0 );
   printf "lat: %.4f\n", $res->resolve_ipresult->latitude;

   # load some xsd file
   my $xsd = load_xsd("http://example.com/eg.xsd");

   # create a new object of of the XSD
   my $obj = $xsd->new( HASH | HASH_REF );

   # Statically created clients
   # on the command line build Client module (and included XSD modules)
   # see L<wsdl-parser> or C<wsdl-parser --help> for more details
   $ wsdl-parser -b ResolveIP ResolveIP 'http://ws.cdyne.com/ip2geo/ip2geo.asmx?wsdl'

   # back in perl

   # the default directory modules are created into
   use lib 'lib';
   # load the ResolveIP client module
   use ResolveIP;
   # Create a client object
   my $client = ResolveIP->new();
   # call the WS
   my $res = $client->resolve_ip( ip_address => '59.106.161.11', license_key => 0 );
   # show the results
   printf "lat: %.4f\n", $res->resolve_ipresult->latitude;

=head1 DESCRIPTION

A perly SOAP clinet library.

=head2 Gotchas

Java style camael case names are converted to the more legible Perl style underscore
sepperated names for everything that doesn't end up being a Perl package or Moose
type. Eg in the Synopsis the operation defined in the IP 2 GEO WSDL is defined as
ResolveIP this is traslated to the perly name resolve_ip.

=head1 SUBROUTINES/METHODS

=over 4

=item C<load_wsdl ($wsdl_location)>

Loads a WSDL file, parses is and generates dynamic Moose objects that represent
the WSDL file and any XML Schema xsd content that it refers to.

See L<W3C::SOAP::WSDL::Parser> for more details.

=item C<load_xsd ($xsd_location)>

Loads an XML Schema (.xsd) file, parses is and generates dynamic Moose objects
that representing that schema and any other included/imported XML Schema
content that it refers to.

See L<W3C::SOAP::XSD::Parser> for more details.

=back

=head1 DIAGNOSTICS

=head1 CONFIGURATION AND ENVIRONMENT

=head1 DEPENDENCIES

=head1 INCOMPATIBILITIES

=head1 BUGS AND LIMITATIONS

There are no known bugs in this module. (Plenty of unknown bugs)

Currently the WSDL handling doesn't deal with more than one input or output
on an opperation or inputs/outputs that aren't specified by an XMLSchema. A;so
operation fault objects aren't yet handled.

Please report problems to Ivan Wills (ivan.wills@gmail.com).

Patches are welcome.

=head1 ALSO SEE

L<XML::LibXML>, L<Moose>, L<MooseX::Types::XMLSchema>

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

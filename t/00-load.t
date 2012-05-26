#!/usr/bin/perl

use strict;
use warnings;
use Test::More tests => 1 + 1;
use Test::NoWarnings;

BEGIN {
	use_ok( 'W3C::SOAP::XSD' );
}

diag( "Testing W3C::SOAP::XSD $W3C::SOAP::XSD::VERSION, Perl $], $^X" );

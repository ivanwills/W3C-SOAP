package W3C::SOAP::Header::Security::Username;

# Created on: 2012-05-23 14:38:06
# Create by:  dev
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
use DateTime;
use Time::HiRes qw/gettimeofday/;
use English qw/ -no_match_vars /;

extends 'W3C::SOAP::Header::Security';

our $VERSION     = version->new('0.0.1');
our @EXPORT_OK   = qw//;
our %EXPORT_TAGS = ();
#our @EXPORT      = qw//;
my $id = 0;

has username => (
    is       => 'rw',
    isa      => 'Str',
    required => 1,
);
has password => (
    is       => 'rw',
    isa      => 'Str',
    required => 1,
);

# Moose 2
#argument to_xml => sub {
sub to_xml {
    my ($self, $xml) = @_;
    my $uname_token = $xml->createElement('wss:UsernameToken');
    $uname_token->setAttribute('xmlns:wsu' => 'http://docs.oasis-open.org/wss/2004/01/oasis-200401-wss-wssecurity-utility-1.0.xsd');
    $uname_token->setAttribute('wsu:Id', 'UsernameToken-' . $id++);

    my $username = $xml->createElement('wss:Username');
    $username->appendChild( $xml->createTextNode($self->username) );
    $uname_token->appendChild($username);

    my $password = $xml->createElement('wss:Password');
    $password->appendChild( $xml->createTextNode($self->password) );
    $password->setAttribute('Type' => 'http://docs.oasis-open.org/wss/2004/01/oasis-200401-wss-username-token-profile-1.0#PasswordText');
    $uname_token->appendChild($password);

    my $nonce_text = '';
    $nonce_text .= ('a'..'z','A'..'Z',0..9)[rand 62] for  1 .. 24;
    my $nonce = $xml->createElement('wss:Nonce');
    $nonce->appendChild( $xml->createTextNode($nonce_text.'==') );
    $nonce->setAttribute('EncodingType' => 'http://docs.oasis-open.org/wss/2004/01/oasis-200401-wss-soap-message-security-1.0#Base64Binary');
    $uname_token->appendChild($nonce);

    my ($seconds, $microseconds) = gettimeofday;
    #TODO is the following nessesary?
    $microseconds =~ s{^(\d\d\d).*}{$1};
    my $date_text = DateTime->now->set_time_zone("Z") . ".${microseconds}Z";
    my $date = $xml->createElement('wsu:Created');
    $date->appendChild( $xml->createTextNode($date_text) );
    $uname_token->appendChild($date);

    # Moose 1
    my $sec = $self->SUPER::to_xml($xml);
    $sec->appendChild($uname_token);

    return $sec;
    # Moose 2
    #return $uname_token;
}

1;

__END__

=head1 NAME

W3C::SOAP::Header::Security::Username - <One-line description of module's purpose>

=head1 VERSION

This documentation refers to W3C::SOAP::Header::Security::Username version 0.1.


=head1 SYNOPSIS

   use W3C::SOAP::Header::Security::Username;

   # Brief but working code example(s) here showing the most common usage(s)
   # This section will be as far as many users bother reading, so make it as
   # educational and exemplary as possible.


=head1 DESCRIPTION

A full description of the module and its features.

May include numerous subsections (i.e., =head2, =head3, etc.).


=head1 SUBROUTINES/METHODS

A separate section listing the public components of the module's interface.

These normally consist of either subroutines that may be exported, or methods
that may be called on objects belonging to the classes that the module
provides.

Name the section accordingly.

In an object-oriented module, this section should begin with a sentence (of the
form "An object of this class represents ...") to give the reader a high-level
context to help them understand the methods that are subsequently described.




=head1 DIAGNOSTICS

A list of every error and warning message that the module can generate (even
the ones that will "never happen"), with a full explanation of each problem,
one or more likely causes, and any suggested remedies.

=head1 CONFIGURATION AND ENVIRONMENT

A full explanation of any configuration system(s) used by the module, including
the names and locations of any configuration files, and the meaning of any
environment variables or properties that can be set. These descriptions must
also include details of any configuration language used.

=head1 DEPENDENCIES

A list of all of the other modules that this module relies upon, including any
restrictions on versions, and an indication of whether these required modules
are part of the standard Perl distribution, part of the module's distribution,
or must be installed separately.

=head1 INCOMPATIBILITIES

A list of any modules that this module cannot be used in conjunction with.
This may be due to name conflicts in the interface, or competition for system
or program resources, or due to internal limitations of Perl (for example, many
modules that use source code filters are mutually incompatible).

=head1 BUGS AND LIMITATIONS

A list of known problems with the module, together with some indication of
whether they are likely to be fixed in an upcoming release.

Also, a list of restrictions on the features the module does provide: data types
that cannot be handled, performance issues and the circumstances in which they
may arise, practical limitations on the size of data sets, special cases that
are not (yet) handled, etc.

The initial template usually just has:

There are no known bugs in this module.

Please report problems to dev (dev@localhost).

Patches are welcome.

=head1 AUTHOR

dev - (dev@localhost)
<Author name(s)>  (<contact address>)

=head1 LICENSE AND COPYRIGHT

Copyright (c) 2012 dev (123 Timbuc Too).
All rights reserved.

This module is free software; you can redistribute it and/or modify it under
the same terms as Perl itself. See L<perlartistic>.  This program is
distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY;
without even the implied warranty of MERCHANTABILITY or FITNESS FOR A
PARTICULAR PURPOSE.

=cut

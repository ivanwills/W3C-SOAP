package W3C::SOAP::Client;

# Created on: 2012-05-28 07:40:20
# Create by:  Ivan Wills
# $Id$
# $Revision$, $HeadURL$, $Date$
# $Revision$, $Source$, $Date$

use Moose;
use version;
use Carp qw/carp croak cluck confess longmess/;
use Scalar::Util;
use List::Util;
#use List::MoreUtils;
use Data::Dumper qw/Dumper/;
use English qw/ -no_match_vars /;
use WWW::Mechanize;
use TryCatch;
use XML::LibXML;
use W3C::SOAP::Exception;

our $VERSION     = version->new('0.0.1');
our @EXPORT_OK   = qw//;
our %EXPORT_TAGS = ();
#our @EXPORT      = qw//;

has location => (
    is       => 'rw',
    isa      => 'Str',
    required => 1,
);
has header => (
    is        => 'rw',
    isa       => 'W3C::SOAP::Header',
    predicate => 'has_header',
    builder   => '_header',
);
has mech => (
    is      => 'rw',
    isa     => 'WWW::Mechanize',
    default => sub { WWW::Mechanize->new },
);

sub request {
    my ($self, $action, $body) = @_;
    warn Dumper $body, "\n";
    my $xml = XML::LibXML->load_xml(string => <<'XML');
<?xml version="1.0" encoding="UTF-8"?>
<soapenv:Envelope xmlns:soapenv="http://schemas.xmlsoap.org/soap/envelope/">
    <soapenv:Body/>
</soapenv:Envelope>
XML

    my $xc = XML::LibXML::XPathContext->new($xml);
    $xc->registerNs('soapenv' => 'http://schemas.xmlsoap.org/soap/envelope/' );
    my ($soap_body) = $xc->findnodes('//soapenv:Body');
    if ( !blessed $body ) {
        $soap_body->appendChild( $xml->createTextNode($body) );
    }
    elsif ( $body->isa('XML::LibXNL::Node') ) {
        $soap_body->appendChild( $body );
    }
    elsif ( $body->can('to_xml') ) {
        for my $node ( $body->to_xml($xml) ) {
            warn $node->toString();
            $soap_body->appendChild( $node );
        }
    }
    else {
        W3C::SOAP::Exception::Input->throw(
            faultcode => 'UNKNOWN SOAP BODY',
            message   => "Don't know how to process ". (ref $body) ."\n",
            error     => undef,
        );
    }

    warn $xml->toString, "\n";
    if ( $self->has_header ) {
        my $node = $self->header->to_xml($xml);
        $xml->firstChild->insertBefore($node, $xml->firstChild->firstChild);
    }
    warn $xml->toString, "\n";

    return $self->send($action, $xml);
}

sub send {
    my ($self, $action, $xml) = @_;

    my $url = $self->location;

    try {
        $self->mech->post(
            $url,
            'Content-Type'     => 'text/xml;charset=UTF-8',
            'SOAPAction'       => qq{"$action"},
            'Proxy-Connection' => 'Keep-Alive',
            'Accept-Encoding'  => 'gzip, deflate',
            Content            => $xml->toString,
        );
    }
    catch ($e) {
        cluck "faultcode => ",$self->mech->res->code," message   => ",$self->mech->res->message,"\n";
        W3C::SOAP::Exception::HTTP->throw(
            faultcode => $self->mech->res->code,
            message   => $self->mech->res->message,
            error     => $e,
        );
    };
    warn $self->mech->content;

    return XML::LibXML->new( string => $self->mech->content );
}

sub _header {
    confess "This builder should be overridden in " . ref $_[0];
}

1;

__END__

=head1 NAME

W3C::SOAP::Client - <One-line description of module's purpose>

=head1 VERSION

This documentation refers to W3C::SOAP::Client version 0.1.


=head1 SYNOPSIS

   use W3C::SOAP::Client;

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

Please report problems to Ivan Wills (ivan.wills@gmail.com).

Patches are welcome.

=head1 AUTHOR

Ivan Wills - (ivan.wills@gmail.com)
<Author name(s)>  (<contact address>)

=head1 LICENSE AND COPYRIGHT

Copyright (c) 2012 Ivan Wills (14 Mullion Close, Hornsby Heights, NSW Australia 2077).
All rights reserved.

This module is free software; you can redistribute it and/or modify it under
the same terms as Perl itself. See L<perlartistic>.  This program is
distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY;
without even the implied warranty of MERCHANTABILITY or FITNESS FOR A
PARTICULAR PURPOSE.

=cut

package W3C::SOAP::Client;

# Created on: 2012-05-28 07:40:20
# Create by:  Ivan Wills
# $Id$
# $Revision$, $HeadURL$, $Date$
# $Revision$, $Source$, $Date$

use Moose;
use warnings;
use version;
use Carp qw/carp croak cluck confess longmess/;
use Scalar::Util;
use List::Util;
use Data::Dumper qw/Dumper/;
use English qw/ -no_match_vars /;
use WWW::Mechanize;
use TryCatch;
use XML::LibXML;
use W3C::SOAP::Exception;
use W3C::SOAP::Header;
use Moose::Util::TypeConstraints qw/duck_type/;

our $VERSION     = version->new('0.0.6');
our $DEBUG_REQUEST_RESPONSE = $ENV{W3C_SOAP_DEBUG_CLIENT};

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
    builder => '_mech',
);
has log => (
    is        => 'rw',
    isa       => duck_type([qw/ debug info warn error fatal /]),
    predicate => 'has_log',
    clearer   => 'clear_log',
);

sub request {
    my ($self, $action, $body) = @_;
    my $xml = $self->build_request_xml($action, $body);

    if ( $self->has_header ) {
        my $node = $self->header->to_xml($xml);
        $xml->firstChild->insertBefore($node, $xml->getDocumentElement->firstChild);
    }

    return $self->send($action, $xml);
}

sub build_request_xml {
    my ($self, $action, $body) = @_;
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
        $soap_body->appendChild( $body->to_xml($xml) );
    }
    else {
        W3C::SOAP::Exception::BadInput->throw(
            faultcode => 'UNKNOWN SOAP BODY',
            message   => "Don't know how to process ". (ref $body) ."\n",
            error     => '',
        );
    }

    return $xml;
}

sub send {
    my ($self, $action, $xml) = @_;
    my $content;

    $self->log->debug("$action REQUEST\n" . $xml->toString) if $self->has_log;
    try {
        $content = $self->_post($action, $xml);
    }
    catch ($e) {
        $self->log->error("$action RESPONSE \n" . $self->mech->res->decoded_content) if $self->has_log;
        my $xml_error = eval { XML::LibXML->load_xml( string => $self->mech->res->content ) };

        if ( $xml_error ) {
            my $ns       = $self->_envelope_ns($xml_error);
            my ($code  ) = $xml_error->findnodes("//$ns\:Body/$ns\:Fault/faultcode");
            my ($string) = $xml_error->findnodes("//$ns\:Body/$ns\:Fault/faultstring");
            my ($actor ) = $xml_error->findnodes("//$ns\:Body/$ns\:Fault/faultactor");
            my ($detail) = $xml_error->findnodes("//$ns\:Body/$ns\:Fault/detail");
            W3C::SOAP::Exception->throw(
                faultcode   => $code   && $code->textContent,
                faultstring => $string && $string->textContent,
                faultactor  => $actor  && $actor->textContent,
                detail      => $detail && $detail->textContent,
                xml         => $xml_error->findnodes("//$ns\:Body/"),
            );
        }
        else {
            W3C::SOAP::Exception::HTTP->throw(
                faultcode => $self->mech->res->code,
                message   => $self->mech->res->message,
                error     => $e,
            );
        }
    };
    $self->log->debug("$action RESPONSE \n$content") if $self->has_log;

    my $xml_response = XML::LibXML->load_xml( string => $content );
    my $ns = $self->_envelope_ns($xml_response);

    my ($node) = $xml_response->findnodes("//$ns\:Body");

    return $node;
}

sub _post {
    my ($self, $action, $xml) = @_;
    my $url = $self->location;

    $self->mech->post(
        $url,
        'Content-Type'     => 'text/xml;charset=UTF-8',
        'SOAPAction'       => qq{"$action"},
        'Proxy-Connection' => 'Keep-Alive',
        'Accept-Encoding'  => 'gzip, deflate',
        Content            => $xml->toString,
    );

    return $self->mech->content;
}

sub _envelope_ns {
    my ($self, $xml) = @_;
    my %map
        = map {$_->name =~ /^xmlns:?(.*)$/; ($_->value => $1)}
        grep { $_->name =~ /^xmlns/ }
        $xml->firstChild->getAttributes;

    return $map{'http://schemas.xmlsoap.org/soap/envelope/'};
}

sub _header {
    W3C::SOAP::Header->new;
}

{
    my $mech;
    sub _mech {
        return $mech if $mech;
        $mech = WWW::Mechanize->new;

        if ($DEBUG_REQUEST_RESPONSE) {
            $mech->add_handler("request_send",  sub { shift->dump( prefix => 'REQUEST  ', maxlength => $ENV{W3C_SOAP_DEBUG_LENGTH} || 1024 ); return });
            $mech->add_handler("response_done", sub { shift->dump( prefix => 'RESPONSE ', maxlength => $ENV{W3C_SOAP_DEBUG_LENGTH} || 1024 ); return });
        }

        return $mech;
    }
}

1;

__END__

=head1 NAME

W3C::SOAP::Client - Client to talk SOAP to a server.

=head1 VERSION

This documentation refers to W3C::SOAP::Client version 0.0.6.

=head1 SYNOPSIS

   use W3C::SOAP::Client;

   # Brief but working code example(s) here showing the most common usage(s)
   # This section will be as far as many users bother reading, so make it as
   # educational and exemplary as possible.


=head1 DESCRIPTION

This module does the actual network connections to a soap server. The clients
generated by L<W3C::SOAP::WSDL::Parser> use this module as their parent.

=head1 SUBROUTINES/METHODS

=over 4

=item C<request ($action, $body)>

Perform a SOAP request to C<location>'s method C<$action> with the object
C<$body> as the SOAP body.

=item C<build_request_xml ($action, $body)>

Builds up the XML of the SOAP request.

=item C<send ($action, $xml)>

Sends the XML (C<$xml>) to the SOAP Server

=back

=head1 DIAGNOSTICS

=head1 CONFIGURATION AND ENVIRONMENT

The environment variable C<W3C_SOAP_DEBUG_CLIENT> can be used to show
request and response XML.

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

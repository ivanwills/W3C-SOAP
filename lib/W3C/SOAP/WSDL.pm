package W3C::SOAP::WSDL;

# Created on: 2012-05-27 18:57:16
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
use TryCatch;

extends 'W3C::SOAP::Client';

our $VERSION     = version->new('0.01');

has header => (
    is        => 'rw',
    isa       => 'W3C::SOAP::Header',
    predicate => 'has_header',
    builder   => '_header',
);

sub _request {
    my ($self, $action, @args) = @_;
    my $meta      = $self->meta;
    my $method    = $self->_get_operation_method($action);
    my $operation = $method->wsdl_operation;
    my $resp;

    if ( $method->has_in_class && $method->has_in_attribute ) {
        my $class = $method->in_class;
        my $att   = $method->in_attribute;
        my $xsd   = $class->new(
            $att => @args == 1 ? $args[0] : {@args},
        );
        my $xsd_ns = $xsd->xsd_ns;
        if ( $xsd_ns !~ m{/$} ) {
            $xsd_ns .= '/';
        }
        $resp = $self->request( "$xsd_ns$operation" => $xsd );
    }
    else {
        $resp = $self->request( $operation, @args );
    }

    if ( $method->has_out_class && $method->has_out_attribute ) {
        my $class = $method->out_class;
        my $att   = $method->out_attribute;
        return $class->new($resp)->$att;
    }
    else {
        return $resp;
    }
}

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
        for my $node ( $body->to_xml($xml) ) {
            $soap_body->appendChild( $node );
        }
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
        $self->log->error("$action RESPONSE \n" . $self->response->content) if $self->has_log;
        my $xml_error = eval { XML::LibXML->load_xml( string => $self->response->content ) };

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
            );
        }
        else {
            W3C::SOAP::Exception::HTTP->throw(
                faultcode => $self->response->code,
                message   => $self->response->message,
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

sub _get_operation_method {
    my ($self, $action) = @_;

    my $method = $self->meta->get_method($action);
    return $method if $method && $method->meta->name eq 'W3C::SOAP::WSDL::Meta::Method';

    for my $super ( $self->meta->superclasses ) {
        next unless $super->can('_get_operation_method');
        $method = $super->_get_operation_method($action);
        return $method if $method && $method->meta->name eq 'W3C::SOAP::WSDL::Meta::Method';
    }

    confess "Could not find any methods called $action!";
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

1;

__END__

=head1 NAME

W3C::SOAP::WSDL - A SOAP WSDL Client object

=head1 VERSION

This documentation refers to W3C::SOAP::WSDL version 0.01.


=head1 SYNOPSIS

   use W3C::SOAP::WSDL;

   # Brief but working code example(s) here showing the most common usage(s)
   # This section will be as far as many users bother reading, so make it as
   # educational and exemplary as possible.


=head1 DESCRIPTION

Inherits from L<W3C::SOAP::Client>

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

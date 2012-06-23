package W3C::SOAP::Exception;
use strict;
use warnings;

use Exception::Class (
    'W3C::SOAP::Exception' => {
        fields => [ qw{ faultcode message } ],
    },
    'W3C::SOAP::Exception::HTTP' => {
        isa => 'W3C::SOAP::Exception',
        fields => [ qw{ faultcode message error } ],
    },

    'W3C::SOAP::Exception::Doomed' => {
        isa => 'W3C::SOAP::Exception',
    },

    'W3C::SOAP::Exception::BadInput' => {
        fields => [ qw{ param message } ],
    },
);


1;

__END__

=head1 NAME

W3C::SOAP::Exception - Exceptions for SOAP Clients etc

=head1 SYNOPSIS

   use W3C::SOAP::Exception;

=head1 DESCRIPTION

Exceptions thrown by L<W3C::SOAP> objects.

=head1 ALSO SEE

L<Exception::Class>

=cut

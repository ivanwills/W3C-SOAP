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

W3C::SOAP::Exception - Sets up exception classes for ESB

=head1 SYNOPSIS

   use W3C::SOAP::Exception;

   # do some ESB action
   my $resp = $self->_esb->action(...);

   # when an error occurs throw the exception
   if ($error) {
       W3C::SOAP::Exception->throw(...);
   }

=head1 DESCRIPTION

This class sets up exception classes that are thrown by ESB modules.

=head1 ALSO SEE

L<Exception::Class>

=cut

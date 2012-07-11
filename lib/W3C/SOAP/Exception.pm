package W3C::SOAP::Exception;
use Moose;
extends 'MooseX::Exception::Base';

has faultcode => (
    is   => 'rw',
    isa  => 'Str',
);
has faultstring => (
    is   => 'rw',
    isa  => 'Str',
    traits => [qw{MooseX::Exception::Stringify}],
);
has faultactor => (
    is   => 'rw',
    isa  => 'Str',
);
has detail => (
    is   => 'rw',
    isa  => 'Str',
);

package W3C::SOAP::Exception::HTTP;
use Moose;
extends 'W3C::SOAP::Exception';

package W3C::SOAP::Exception::Doomed;
use Moose;
extends 'W3C::SOAP::Exception';

package W3C::SOAP::Exception::BadInput;
use Moose;
extends 'MooseX::Exception::Base';
has param => (
    is   => 'rw',
    isa  => 'Str',
);
has message => (
    is   => 'rw',
    isa  => 'Str',
    traits => [qw{MooseX::Exception::Stringify}],
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

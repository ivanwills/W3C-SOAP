package W3C::SOAP::WSDL::Traits;

# Created on: 2012-05-26 23:08:42
# Create by:  Ivan Wills
# $Id$
# $Revision$, $HeadURL$, $Date$
# $Revision$, $Source$, $Date$

use strict;
use warnings;
use version;
use Moose::Role;
use Carp;
use Data::Dumper qw/Dumper/;
use English qw/ -no_match_vars /;
use Moose::Util::TypeConstraints;

our $VERSION     = version->new('0.0.1');

Moose::Util::meta_attribute_alias('W3C::SOAP::WSDL');

has wsdl_opperation => (
    is        => 'rw',
    isa       => 'Str',
    predicate => 'has_wsdl_opperation',
);
has in_class => (
    is        => 'rw',
    isa       => 'Str',
    predicate => 'has_in_class',
);
has in_attribute => (
    is        => 'rw',
    isa       => 'Str',
    default   => 0,
    predicate => 'has_in_attribute',
);
has out_class => (
    is        => 'rw',
    isa       => 'Str',
    default   => 1,
    predicate => 'has_out_class',
);
has out_attribute => (
    is        => 'rw',
    isa       => 'Str',
    predicate => 'has_out_attribute',
);
has security => (
    is        => 'rw',
    isa       => 'Str',
    predicate => 'has_security',
);

1;

__END__

=head1 NAME

W3C::SOAP::WSDL::Traits - Specifies the traits of an WSDL Moose attribute

=head1 VERSION

This documentation refers to W3C::SOAP::WSDL::Traits version 0.1.


=head1 SYNOPSIS

   use W3C::SOAP::WSDL::Traits;

   # Brief but working code example(s) here showing the most common usage(s)
   # This section will be as far as many users bother reading, so make it as
   # educational and exemplary as possible.


=head1 DESCRIPTION

Defines the Moose attribute trait C<W3C::SOAP::WSDL>. This specifies a number
of properties that an attribute can have which helps the processing of
objects representing WSDLs.

=over 4

=item C<xs_perl_module>

If the attribute has a type that is a perl module (or a list of a perl module)
This parameter helps in the coercing of XML nodes to the attribute.

=item C<xs_min_occurs>

This represents the minimum number of occurrences of elements in a list.

=item C<xs_max_occurs>

This specifies the maximum number of occurrences of elements in a list.

=item C<xs_name>

This is the name as it appears in the WSDL

=item C<xs_type>

This is the type as it appears in the WSDL (this will be translated
to perl types/modules specified by the isa property)

=item C<xs_choice_group>

If a complex element has choices this records the grouping of those
choices.

=back

=head1 SUBROUTINES/METHODS

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

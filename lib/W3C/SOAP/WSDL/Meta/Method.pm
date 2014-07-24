package W3C::SOAP::WSDL::Meta::Method;

# Created on: 2012-07-15 19:45:13
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

extends 'Moose::Meta::Method';

our $VERSION     = version->new('0.07');

has wsdl_operation => (
    is        => 'rw',
    isa       => 'Str',
    required  => 1,
    predicate => 'has_wsdl_operation',
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
has in_header_class => (
    is        => 'rw',
    isa       => 'Str',
    predicate => 'has_in_header_class',
);
has in_header_attribute => (
    is        => 'rw',
    isa       => 'Str',
    default   => 0,
    predicate => 'has_in_header_attribute',
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
has out_header_class => (
    is        => 'rw',
    isa       => 'Str',
    predicate => 'has_out_header_class',
);
has out_header_attribute => (
    is        => 'rw',
    isa       => 'Str',
    default   => 0,
    predicate => 'has_out_header_attribute',
);
has faults => (
    is        => 'rw',
    isa       => 'ArrayRef[HashRef]',
    predicate => 'has_faults',
);
has security => (
    is        => 'rw',
    isa       => 'Str',
    predicate => 'has_security',
);


1;

__END__

=head1 NAME

W3C::SOAP::WSDL::Meta::Method - <One-line description of module's purpose>

=head1 VERSION

This documentation refers to W3C::SOAP::WSDL::Meta::Method version 0.07.


=head1 SYNOPSIS

   use W3C::SOAP::WSDL::Meta::Method;

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

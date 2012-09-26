package W3C::SOAP::Utils;

# Created on: 2012-06-01 12:15:15
# Create by:  dev
# $Id$
# $Revision$, $HeadURL$, $Date$
# $Revision$, $Source$, $Date$

use strict;
use warnings;
use version;
use Carp;
use Scalar::Util;
use List::Util;
use Data::Dumper qw/Dumper/;
use English qw/ -no_match_vars /;
use W3C::SOAP::WSDL::Meta::Method;

Moose::Exporter->setup_import_methods(
    as_is     => ['split_ns', 'xml_error'],
    with_meta => ['operation'],
);

our $VERSION     = version->new('0.0.4');

sub split_ns {
    my ($tag) = @_;
    confess "No XML tag passed to split!\n" unless defined $tag;
    my ($ns, $name) = split /:/, $tag, 2;
    return $name ? ($ns, $name) : ('', $ns);
}

sub xml_error {
    my ($node) = @_;
    my @lines  = split /\r?\n/, $node->toString;
    my $indent = '';
    if ( $lines[0] !~ /^\s+/ && $lines[-1] =~ /^(\s+)/ ) {
        $indent = $1;
    }
    my $error = $indent . $node->toString."\n at ";
    $error .= "line - ".$node->line_number.' ' if $node->line_number;
    $error .= "path - ".$node->nodePath;

    return $error;
}

sub operation {
    my ( $meta, $name, %options ) = @_;
    $meta->add_method(
        $name,
        W3C::SOAP::WSDL::Meta::Method->wrap(
            body            => sub { shift->_request($name => @_) },
            package_name    => $meta->name,
            name            => $name,
            %options,
        )
    );
    return;
}

1;

__END__

=head1 NAME

W3C::SOAP::Utils - Utility functions to be used with C<W3C::SOAP> modules

=head1 VERSION

This documentation refers to W3C::SOAP::Utils version 0.0.4.

=head1 SYNOPSIS

   use W3C::SOAP::Utils;

   # splits tags with an optional XML namespace prefix
   my ($namespace, $tag) = split_ns('xs:thing');
   # $namespace = xs
   # $tag = thing

   # In a WSDL package to generate an operation method:
   operation wsdl_op => (
       wsdl_operation => 'WsdlOp',
       in_class       +> 'MyApp::Some::XSD',
       in_attribute   +> 'wsdl_op_request',
       out_class      +> 'MyApp::Some::XSD',
       out_attribute  +> 'wsdl_op_response',
   );

=head1 DESCRIPTION

Utility Functions

=head1 SUBROUTINES

=over 4

=item C<split_ns ($name)>

Splits an XML tag's namespace from the tag name

=item C<xml_error ($xml_node)>

Pretty format the C<$xml_node> for an error message

=back

=head1 MOOSE HELPERS

=over 4

=item C<operation ($name, %optisns)>

Generates a SOAP operation method with the name C<$name>

The options are:

=over 4

=item C<wsdl_operation>

The name of the operation from the WSDL

=item C<in_class>

The name of the XSD generated module that the inputs should be made against

=item C<in_attribute>

The particular element form the C<in_class> XSD

=item C<out_class>

The name of the XSD generated module that the outputs should be passed to

=item C<out_attribute>

The particular element form the C<out_class> XSD that contains the results.

=back

=back

=head1 DIAGNOSTICS

=head1 CONFIGURATION AND ENVIRONMENT

=head1 DEPENDENCIES

=head1 INCOMPATIBILITIES

=head1 BUGS AND LIMITATIONS

There are no known bugs in this module.

Please report problems to Ivan Wills - (ivan.wills@gmail.com)

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

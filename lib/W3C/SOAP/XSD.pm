package W3C::SOAP::XSD;

# Created on: 2012-05-26 23:50:44
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
use Moose::Util::TypeConstraints;
use MooseX::Types::XMLSchema;
use W3C::SOAP::XSD::Types qw/:all/;
use W3C::SOAP::XSD::Traits;
use W3C::SOAP::Utils qw/split_ns/;
use TryCatch;
use DateTime::Format::Strptime qw/strptime/;

our $VERSION     = version->new('0.0.1');
our @EXPORT_OK   = qw//;
our %EXPORT_TAGS = ();
#our @EXPORT      = qw//;

has xsd_ns => (
    is  => 'rw',
    isa => 'Str',
);
has xsd_ns_name => (
    is         => 'rw',
    isa        => 'Str',
    predicate  => 'has_xsd_ns_name',
    builder    => '_xsd_ns_name',
    lazy_build => 1,
);

{
    my %required;
    my $require = sub {
        my ($module) = @_;
        return if $required{$module}++;

        my $file = "$module.pm";
        $file =~ s{::}{/}g;
        require $file;
    };
    around BUILDARGS => sub {
        my ($orig, $class, @args) = @_;
        my $args
            = !@args     ? {}
            : @args == 1 ? $args[0]
            :              {@args};

        if ( blessed $args && $args->isa('XML::LibXML::Node') ) {
            my $xml   = $args;
            my $child = $xml->firstChild;
            my $map   = $class->xml2perl_map;
            my ($element)  = $class =~ /::([^:]+)$/;
            $args = {};

            while ($child) {
                if ( $child->nodeName !~ /^#/ ) {
                    my ($node_ns, $node) = split_ns($child->nodeName);
                    confess "Could not get node from (".$child->nodeName." via $node_ns, $node)\n", Dumper $map
                        if !$map->{$node};
                    my $attrib = $map->{$node};
                    $node = $attrib->name;
                    my $module = $attrib->has_xs_perl_module ? $attrib->xs_perl_module : undef;
                    $require->($module) if $module;
                    my $value  = $module ? $module->new($child) : $child->textContent;

                    $args->{$node}
                        = !exists $args->{$node}        ? $value
                        : ref $args->{$node} ne 'ARRAY' ? [   $args->{$node} , $value ]
                        :                                 [ @{$args->{$node}}, $value ];
                }
                $child = $child->nextSibling;
            }
        }

        return $class->$orig($args);
    };
}

my %ns_map;
my $count = 0;
sub _xsd_ns_name {
    my ($self) = @_;
    my $ns = $self->xsd_ns;

    return $ns_map{$ns} if $ns_map{$ns};

    return $ns_map{$ns} = 'WSX' . $count++;
}

sub _from_xml {
    my ($class, $type) = @_;
    my $xml = $_;
    die "Unknown conversion " . ( (ref $xml) || $xml )
        if !$xml || !blessed $xml || !$xml->isa('XML::LibXML::Node');

    try {
        return $type->new($xml);
    }
    catch ($e) {
        $e =~ s/ at .*//ms;
        warn "$class Failed in building from $type\->new($xml) : $e\n",
            "Will use :\n\t'",
            $xml->toString,
            "'\n\tor\n\t'",
            $xml->textContent,"'\n",
            '*' x 222,
            "\n";
    }
    return $xml->textContent;
}

sub xml2perl_map {
    my ($class) = @_;
    my %map;

    for my $attr ($class->get_xml_nodes) {
        $map{$attr->xs_name} = $attr;
    }
    return \%map;
}

# recursivly try to find the default value for an attribute
sub _get_attribute_default {
    my ($class, $attribute) = @_;
    my $meta = $class->meta;
    my $attrib = $meta->get_attribute($attribute);

    return $attrib->default if $attrib;

    for my $super ( $meta->superclasses ) {
        my $default = $super->_get_attribute_default($attribute);
        return $default if $default;
    }

    return;
}

sub to_xml {
    my ($self, $xml) = @_;
    my $child;
    my $meta = $self->meta;
    my @attributes = $self->get_xml_nodes;

    my @nodes;

    for my $att (@attributes) {
        my $name = $att->name;

        # skip attributes that are not XSD attributes
        next if !$att->does('W3C::SOAP::XSD');
        my $has = "has_$name";

        # skip sttributes that are not set
        next if !$self->$has;

        my $xml_name = $att->has_xs_name ? $att->xs_name : $name;
        my $xsd_ns_name = $self->xsd_ns_name;

        my $value = $self->$name;

        if ( ref $value eq 'ARRAY' ) {
            for my $item (@$value) {
                my $tag = $xml->createElement($xsd_ns_name . ':' . $xml_name);
                $tag->setAttribute("xmlns:$xsd_ns_name" => $self->xsd_ns) if $self->xsd_ns;

                if ( blessed($item) && $item->can('to_xml') ) {
                    $item->xsd_ns_name( $xsd_ns_name ) if !$item->has_xsd_ns_name;
                    my @children = $item->to_xml($xml);
                    $tag->appendChild($_) for @children;
                }
                else {
                    $tag->appendChild( $xml->createTextNode("$item") );
                }

                push @nodes, $tag;
            }
        }
        else {
            my $tag = $xml->createElement($xsd_ns_name . ':' . $xml_name);
            $tag->setAttribute("xmlns:$xsd_ns_name" => $self->xsd_ns) if $self->xsd_ns;

            if ( blessed($value) && $value->can('to_xml') ) {
                $value->xsd_ns_name( $xsd_ns_name ) if !$value->has_xsd_ns_name;
                my @children = $value->to_xml($xml);
                $tag->appendChild($_) for @children;
            }
            else {
                $tag->appendChild( $xml->createTextNode("$value") );
            }

            push @nodes, $tag;
        }
    }

    return @nodes;
}

sub to_data {
    my ($self, %option) = @_;
    my $child;
    my $meta = $self->meta;
    my @attributes = $self->get_xml_nodes;

    my %nodes;

    for my $att (@attributes) {
        my $name = $att->name;

        # skip attributes that are not XSD attributes
        next if !$att->does('W3C::SOAP::XSD');
        my $has = "has_$name";

        # skip sttributes that are not set
        next if !$self->$has;

        my $key_name = $att->has_xs_name && $option{like_xml} ? $att->xs_name : $name;
        my $value = $self->$name;

        if ( ref $value eq 'ARRAY' ) {
            for my $element (@$value) {
                if ( blessed($element) && $element->can('to_data') ) {
                    $element = $element->to_data(%option);
                }
            }
        }
        elsif ( blessed($value) && $value->can('to_data') ) {
            $value = $value->to_data(%option);
        }
        elsif ($option{stringify}) {
            $value = defined $value ? "$value" : $value;
        }

        $nodes{$key_name} = $value;
    }

    return \%nodes;
}

sub get_xml_nodes {
    my ($self) = @_;
    my $meta = $self->meta;

    my @parent_nodes;
    my @supers = $meta->superclasses;
    for my $super (@supers) {
        push @parent_nodes, $super->get_xml_nodes if $super ne __PACKAGE__ && UNIVERSAL::can($super, 'get_xml_nodes');
    }

    return @parent_nodes, map {
            $meta->get_attribute($_)
        }
        sort {
            $meta->get_attribute($a)->insertion_order <=> $meta->get_attribute($b)->insertion_order
        }
        grep {
            $meta->get_attribute($_)->does('W3C::SOAP::XSD::Traits')
        }
        $meta->get_attribute_list;
}

my %types;
sub xsd_subtype {
    my ($self, %args) = @_;
    my $parent_type = $args{module} || $args{parent};
    # upgrade dates
    $parent_type = 'xsd:date'     if $parent_type eq 'xs:date';
    $parent_type = 'xsd:dateTime' if $parent_type eq 'xs:dateTime';
    $parent_type = 'xsd:boolean'  if $parent_type eq 'xs:boolean';
    $parent_type = 'xsd:double'   if $parent_type eq 'xs:double';

    my $parent_type_name = $args{list} ? "ArrayRef[$parent_type]" : $parent_type;
    my $subtype = $parent_type =~ /^xsd:\w/ && Moose::Util::TypeConstraints::find_type_constraint($parent_type_name);
    return $subtype if $subtype;

    $subtype = subtype
        as $parent_type_name,
        message {"'$_' failed to validate as a $parent_type"};

    if ( $args{list} ) {
        if ( $args{module} ) {
            coerce $subtype =>
                from 'xml_node' =>
                via { [$parent_type->new($_)] };
            coerce $subtype =>
                from 'HashRef' =>
                via { [$parent_type->new($_)] };
            coerce $subtype =>
                from 'ArrayRef[HashRef]' =>
                via { [ map { $parent_type->new($_) } @$_ ] };
            coerce $subtype =>
                from $parent_type =>
                via { [$_] };
        }
        else {
            coerce $subtype =>
                from 'xml_node' =>
                via { [$_->textContent] };
            coerce $subtype =>
                from 'ArrayRef[xml_node]' =>
                via { [ map { $_->textContent } @$_ ] };
        }
    }
    elsif ( $args{module} ) {
        coerce $subtype =>
            from 'xml_node' =>
            via { $parent_type->new($_) };
        coerce $subtype =>
            from 'HashRef' =>
            via { $parent_type->new($_) };
    }
    else {
        coerce $subtype =>
            from 'xml_node' =>
            via { $_->textContent };
    }

    return $subtype;
}

1;

__END__

=head1 NAME

W3C::SOAP::XSD - The parent module to XSD modules

=head1 VERSION

This documentation refers to W3C::SOAP::XSD version 0.1.

=head1 SYNOPSIS

   use W3C::SOAP::XSD;

   # Brief but working code example(s) here showing the most common usage(s)
   # This section will be as far as many users bother reading, so make it as
   # educational and exemplary as possible.


=head1 DESCRIPTION


=head1 SUBROUTINES/METHODS

=over 4

=item C<xml2perl_map ()>

Returns a mapping of XML tag elements to perl attributes

=item C<to_xml ($xml)>

Converts the object to an L<XML::LibXML> node.

=item C<to_data (%options)>

Converts this object to a perl data structure. If C<$option{like_xml}> is
specified and true, the keys will be the same as the XML tags otherwise the
keys will be perl names. If C<$option{stringify}> is true and specified
any non XSD objects will be stringified (eg DateTime objects).

=item C<get_xml_nodes ()>

Returns a list of attributes of the current object that have the
C<W3C::SOAP::XSD> trait (which is defined in L<W3C::SOAP::XSD::Traits>)

=item C<xsd_subtype ()>

Helper method to create XSD subtypes that do coercions form L<XML::LibXML>
objects and strings.

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

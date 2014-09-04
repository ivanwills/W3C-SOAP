#!/usr/bin/perl

use strict;
use warnings;
use Test::More;
BEGIN {
    eval { require Test::XML };
    if ($@) {
        plan(skip_all => "Can't run with out Test::XML");
    }
    Test::XML->import;
};
use Path::Class;
use Data::Dumper qw/Dumper/;
use File::ShareDir qw/dist_dir/;
use XML::LibXML;
use W3C::SOAP::XSD::Parser qw/load_xsd/;
use lib file($0)->parent->subdir('lib').'';

my $dir = file($0)->parent;

plan( skip_all => 'Test can only be run if test directory is writable' ) if !-w $dir;

my @xsds = grep {-d $_} $dir->subdir('xsds')->children;

for my $xsd (@xsds) {
    test_xsd($xsd);
}

done_testing();
exit;

sub test_xsd {
    my ($xsd) = @_;
    note $xsd;
    my ($name) = $xsd =~ m{/([^/]+)$};
    $name = join "::", map { ucfirst lc $_ } split /[\W_]+/, $name;

    TODO: {
        local $TODO = -f "$xsd/todo" ? "Fix these tests" : undef;

        my ($module) = eval { load_xsd("$xsd/test.xsd") };
        ok $module, "$name - Get expected module name";

        # get all the data tests
        my @files = $xsd->children;
        my @perl = grep {/[.]pl$/} @files;
        my @xml  = grep {/[.]xml$/} @files;
        my %map;
        for my $file (@perl) {
            my $name = $file->basename;
            $name =~ s/[.].*$//;
            $map{$name}{perl} = eval $file->slurp;
        }
        for my $file (@xml) {
            my $name = $file->basename;
            $name =~ s/[.].*$//;
            $map{$name}{xml} = $file->slurp;
            $map{$name}{file} = $file;
        }

        for my $test (keys %map) {
            my $xml = XML::LibXML->load_xml(location => $map{$test}{file});
            my $from_perl = $module->new($map{$test}{perl});
            my $from_xml  = $module->new($xml);
            is_deeply $from_perl->to_data, $from_xml->to_data, "$name - Generated object are the same"
                or note Dumper $from_perl->to_data, $from_xml->to_data;

            my @child = $from_perl->to_xml($xml);
            is_xml $xml->firstChild->toString, $child[0]->toString, "$name - XML matches"
                or note "\n", $xml->firstChild->toString, "\n", $child[0]->toString, "\n";
        }
    }

    return;
}

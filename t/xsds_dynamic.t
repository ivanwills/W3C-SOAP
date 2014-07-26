#!/usr/bin/perl

use strict;
use warnings;
use Test::More;
use Path::Class;
use Data::Dumper qw/Dumper/;
use File::ShareDir qw/dist_dir/;
use Template;
use W3C::SOAP::XSD::Parser qw/load_xsd/;
use lib file($0)->parent->subdir('lib').'';

my $dir = file($0)->parent;

plan( skip_all => 'Test can only be run if test directory is writable' ) if !-w $dir;

my @xsds = grep {-d $_} $dir->subdir('xsds')->children;

for my $xsd (@xsds) {
    next if $xsd =~ /no/;
    test_xsd($xsd);
}

done_testing();
exit;

sub test_xsd {
    my ($xsd) = @_;

    my ($module) = load_xsd("$xsd/test.xsd");
    ok $module, "Get expected module name";

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

    warn Dumper \%map;
    for my $test (keys %map) {
        my $from_perl = $module->new($map{$test}{perl});
        my $from_xml  = $module->new( xml => $map{$test}{file} );
        is_deeply $from_perl->to_data, $from_xml->to_data, 'Generated object are the same'
            or note Dumper $from_perl->to_data, $from_xml->to_data;
        my $xml = XML::LibXML->load_xml(string => '<?xml version="1.0"?><doc><a/></doc>');
        my @child = $from_perl->to_xml($xml);
        warn @child;
        warn Dumper @child;
        $xml->replaceChild($xml->firstChild, @child);
        warn $xml->toString;
    }

    return;
}

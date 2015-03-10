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
use Template;
use XML::LibXML;
use W3C::SOAP::XSD::Parser;
use lib file($0)->parent->subdir('lib').'';

my $dir = file($0)->parent;

plan( skip_all => 'Test can only be run if test directory is writable' ) if !-w $dir;

# set up templates
my $template = Template->new(
    INCLUDE_PATH => dist_dir('W3C-SOAP').':'.$dir->subdir('../templates'),
    INTERPOLATE  => 0,
    EVAL_PERL    => 1,
);

my @xsds = grep {-d $_} $dir->subdir('xsds')->children;

for my $xsd (@xsds) {
    next if @ARGV && $xsd ne "t/xsds/$ARGV[0]";
    subtest $xsd, sub { test_xsd($xsd); };
}

cleanup();
done_testing();
exit;

sub test_xsd {
    my ($xsd) = @_;
    note $xsd;
    my ($name) = $xsd =~ m{/([^/]+)$};
    $name = join "::", map { ucfirst lc $_ } split /[\W_]+/, $name;

    my $todo = do "$xsd/todo" || {};
    TODO: {
        local $TODO;

        # create the parser object
        my $parser = eval {
            W3C::SOAP::XSD::Parser->new(
                location    => $xsd->file('test.xsd').'',
                template    => $template,
                lib         => $dir->subdir('lib').'',
                module_base => "XSDs::$name",
                ns_module_map => {},
            )
        };
        $TODO = $todo->{create};
        ok $parser, "$name -  parser created";

        my $module = $parser->write_modules();
        $TODO = $todo->{name};
        ok $module, "$name - Get expected module name";
        $TODO = $todo->{require};
        require_ok $module;

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
            $TODO = $todo->{$test}{xml_to_perl};
            is_deeply $from_perl->to_data, $from_xml->to_data, "$xsd/$test $name - Generated object are the same"
                or note Dumper $from_perl->to_data, $from_xml->to_data;

            my @child = $from_perl->to_xml($xml);
            $TODO = $todo->{$test}{perl_to_xml};
            is_xml $xml->firstChild->toString, $child[0]->toString, "$xsd/$test $name - XML matches"
                or note "\n", $xml->firstChild->toString, "\n", $child[0]->toString, "\n";
        }
    }

    return;
}

sub cleanup {
}

#!/usr/bin/perl

use strict;
use warnings;
use Test::More;
use Path::Class;
use File::ShareDir qw/dist_dir/;
use Template;
use W3C::SOAP::XSD::Parser;

my $dir = file($0)->parent;

plan( skip_all => 'Test can only be run if test directory is writable' ) if !-w $dir;

# set up templates
my $template = Template->new(
    INCLUDE_PATH => dist_dir('W3C-SOAP').':'.$dir->subdir('../templates'),
    INTERPOLATE  => 0,
    EVAL_PERL    => 1,
);
# create the parser object
my $parser = W3C::SOAP::XSD::Parser->new(
    location      => $dir->file('eg.xsd').'',
    template      => $template,
    lib           => $dir->subdir('lib').'',
    ns_module_map => {
        'urn:eg.schema.org'     => 'MyApp::Eg',
        'urn:parent.schema.org' => 'MyApp::Parent',
    },
);

parser();
$parser->write_modules;
written_modules();
#cleanup();
done_testing();
exit;

sub parser {
    ok $parser, "Got a parser object";
    is $parser->documents->[0]->target_namespace, 'urn:eg.schema.org', "Get target namespace";
    ok scalar( @{ $parser->documents->[0]->elements }      ), "Got some elements";
    ok scalar( @{ $parser->documents->[0]->simple_types }  ), "Got some simple types";
    ok scalar( @{ $parser->documents->[0]->complex_types } ), "Got some complex types";
}

sub written_modules {
    push @INC, $dir->subdir('lib').'';
    require_ok('MyApp::Eg');
    require_ok('MyApp::Parent');
    my $eg = eval {
        MyApp::Eg->new(
            el1 => '1234',
            el2 => 1234,
            el3 => 'abcd',
            el4 => {
                first_thing => 'a string',
                second_thing => 'SUCCESS',
            },
            el5 => {
                first_thing => 'another string',
                second_thing => 'FAILURE',
            },
        )
    };
    ok !$@, "No error in creating eg object"
        or diag $@;
    isa_ok $eg, 'MyApp::Eg', 'Get an actual object';
}

sub cleanup {
    unlink $dir->file('lib/MyApp/Eg.pm');
    unlink $dir->file('lib/MyApp/Eg/Types.pm');
    unlink $dir->file('lib/MyApp/Eg/Base.pm');
    rmdir  $dir->file('lib/MyApp/Eg');
    unlink $dir->file('lib/MyApp/Parent.pm');
    unlink $dir->file('lib/MyApp/Parent/Types.pm');
    unlink $dir->file('lib/MyApp/Parent/Base.pm');
    rmdir  $dir->file('lib/MyApp/Parent');
}

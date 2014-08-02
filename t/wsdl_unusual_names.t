#!/usr/bin/perl

use strict;
use warnings;
use Test::More;
use Path::Class;
use Data::Dumper qw/Dumper/;
use File::ShareDir qw/dist_dir/;
use Template;
use W3C::SOAP::WSDL::Parser;
use lib file($0)->parent->subdir('lib').'';
use MechMock;

my $dir = file($0)->parent;

plan( skip_all => 'Test can only be run if test directory is writable' ) if !-w $dir;

# set up templates
my $template = Template->new(
    INCLUDE_PATH => dist_dir('W3C-SOAP').':'.$dir->subdir('../templates'),
    INTERPOLATE  => 0,
    EVAL_PERL    => 1,
);
my $ua = MechMock->new;
# create the parser object
my $parser = W3C::SOAP::WSDL::Parser->new(
    location      => $dir->file('unusual_names.wsdl').'',
    module        => 'MyApp::WsdlUnusual',
    template      => $template,
    lib           => $dir->subdir('lib').'',
    ns_module_map => {
        'urn:UnusualNames'     => 'MyApp::Unusual',
    },
);

parser();
$parser->write_modules;
written_modules();
cleanup();
done_testing();
exit;

sub parser {
    ok $parser, "Got a parser object";
    is $parser->document->target_namespace, 'urn:UnusualNames', "Get target namespace";
    ok scalar( @{ $parser->document->messages }      ), "Got some messages";
    ok scalar( @{ $parser->document->schemas }  ), "Got some schemas";
    ok scalar( @{ $parser->document->port_types } ), "Got some port types";
}

sub written_modules {
    push @INC, $dir->subdir('lib').'';
    require_ok('MyApp::WsdlUnusual');
    my $eg = MyApp::WsdlUnusual->new;

    isa_ok $eg, 'MyApp::WsdlUnusual', 'Create the object correctly';
}

sub cleanup {
    $dir->subdir('lib/MyApp')->rmtree() or note 'Could not remove lib/MyApp/Eg/Base.pm';
}

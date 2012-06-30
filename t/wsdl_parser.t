#!/usr/bin/perl

use strict;
use warnings;
use Test::More;
use Path::Class;
use Data::Dumper qw/Dumper/;
use File::ShareDir qw/dist_dir/;
use Template;
use W3C::SOAP::WSDL::Parser;

my $dir = file($0)->parent;

plan( skip_all => 'Test can only be run if test directory is writable' ) if !-w $dir;

# set up templates
my $template = Template->new(
    INCLUDE_PATH => dist_dir('W3C-SOAP').':'.$dir->subdir('../templates'),
    INTERPOLATE  => 0,
    EVAL_PERL    => 1,
);
# create the parser object
my $parser = W3C::SOAP::WSDL::Parser->new(
    location      => $dir->file('eg.wsdl').'',
    module        => 'MyApp::WsdlEg',
    template      => $template,
    lib           => $dir->subdir('lib').'',
    ns_module_map => {
        'urn:eg.schema.org'     => 'MyApp::Eg',
        'urn:parent.schema.org' => 'MyApp::Parent',
        'urn:other.schema.org'  => 'MyApp::Other',
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
    is $parser->document->target_namespace, 'urn:eg.schema.org', "Get target namespace";
    ok scalar( @{ $parser->document->messages }      ), "Got some messages";
    ok scalar( @{ $parser->document->schemas }  ), "Got some schemas";
    ok scalar( @{ $parser->document->port_types } ), "Got some port types";
}

sub written_modules {
    push @INC, $dir->subdir('lib').'';
    require_ok('MyApp::WsdlEg');
    my $eg = MyApp::WsdlEg->new;

    isa_ok $eg, 'MyApp::WsdlEg', 'Create the object correctly';
}

sub cleanup {
    unlink $dir->file('lib/MyApp/WsdlEg.pm');
    unlink $dir->file('lib/MyApp/Eg.pm');
    unlink $dir->file('lib/MyApp/Eg/Types.pm');
    unlink $dir->file('lib/MyApp/Eg/Base.pm');
    rmdir  $dir->file('lib/MyApp/Eg');
    unlink $dir->file('lib/MyApp/Parent.pm');
    unlink $dir->file('lib/MyApp/Parent/Types.pm');
    unlink $dir->file('lib/MyApp/Parent/Base.pm');
    rmdir  $dir->file('lib/MyApp/Parent');
}

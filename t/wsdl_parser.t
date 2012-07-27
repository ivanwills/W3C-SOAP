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
my $mech = MechMock->new;
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
    $eg->mech($mech);

    isa_ok $eg, 'MyApp::WsdlEg', 'Create the object correctly';

    $mech->content(<<"XML");
<?xml version="1.0" encoding="UTF-8"?>
<soapenv:Envelope xmlns:soapenv="http://schemas.xmlsoap.org/soap/envelope/">
    <soapenv:Body xmlns:eg="urn:eg.schema.org">
        <eg:el2>2</eg:el2>
    </soapenv:Body>
</soapenv:Envelope>
XML
    my $resp = $eg->first_action(first_thing => 'test');
    is $resp, 2, "get result back";
}

sub cleanup {
    unlink $dir->file('lib/MyApp/Eg/Anon0.pm')                or warn 'Could not remove lib/MyApp/Eg/Anon0.pm';
    unlink $dir->file('lib/MyApp/Eg/Anon1.pm')                or warn 'Could not remove lib/MyApp/Eg/Anon1.pm';
    unlink $dir->file('lib/MyApp/Eg/Anon2.pm')                or warn 'Could not remove lib/MyApp/Eg/Anon2.pm';
    unlink $dir->file('lib/MyApp/Eg/Base.pm')                 or warn 'Could not remove lib/MyApp/Eg/Base.pm';
    unlink $dir->file('lib/MyApp/Eg/localComplexThing.pm')    or warn 'Could not remove lib/MyApp/Eg/localComplexThing.pm';
    unlink $dir->file('lib/MyApp/Eg/localOther.pm')           or warn 'Could not remove lib/MyApp/Eg/localOther.pm';
    unlink $dir->file('lib/MyApp/Eg.pm')                      or warn 'Could not remove lib/MyApp/Eg.pm';
    unlink $dir->file('lib/MyApp/Other/Base.pm')              or warn 'Could not remove lib/MyApp/Other/Base.pm';
    unlink $dir->file('lib/MyApp/Other/otherComplexThing.pm') or warn 'Could not remove lib/MyApp/Other/otherComplexThing.pm';
    unlink $dir->file('lib/MyApp/Other.pm')                   or warn 'Could not remove lib/MyApp/Other.pm';
    unlink $dir->file('lib/MyApp/Parent/Base.pm')             or warn 'Could not remove lib/MyApp/Parent/Base.pm';
    unlink $dir->file('lib/MyApp/Parent/complexThing.pm')     or warn 'Could not remove lib/MyApp/Parent/complexThing.pm';
    unlink $dir->file('lib/MyApp/Parent/moreComplexThing.pm') or warn 'Could not remove lib/MyApp/Parent/moreComplexThing.pm';
    unlink $dir->file('lib/MyApp/Parent.pm')                  or warn 'Could not remove lib/MyApp/Parent.pm';
    unlink $dir->file('lib/MyApp/WsdlEg.pm')                  or warn 'Could not remove lib/MyApp/WsdlEg.pm';

    rmdir  $dir->file('lib/MyApp/Parent');
    rmdir  $dir->file('lib/MyApp/Other');
    rmdir  $dir->file('lib/MyApp/Eg');
    rmdir  $dir->file('lib/MyApp');
}

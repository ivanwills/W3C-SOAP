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
    location      => $dir->file('eg.wsdl').'',
    module        => 'MyApp::WsdlEg',
    template      => $template,
    lib           => $dir->subdir('lib').'',
    ns_module_map => {},
);

my ($class) = eval { $parser->dynamic_classes };
ok !$@, "Create dynamic classes correctly"
    or BAIL_OUT($@);

dynamic_modules($class);
done_testing();
exit;

sub dynamic_modules {
    note my ($class) = @_;
    my $wsdl = $class->new;
    $wsdl->ua($ua);
    can_ok $wsdl, 'first_action';
    my $action = $wsdl->meta->get_method('first_action');
    is $action->wsdl_operation, 'firstAction', 'Have an operation';
    is $action->in_class, 'Dynamic::XSD::Org::Schema::Eg::v1', 'Input class is correct';

    $ua->content(<<"XML");
<?xml version="1.0" encoding="UTF-8"?>
<soapenv:Envelope xmlns:soapenv="http://schemas.xmlsoap.org/soap/envelope/">
    <soapenv:Body xmlns:eg="http://eg.schema.org/v1">
        <eg:el2>2</eg:el2>
    </soapenv:Body>
</soapenv:Envelope>
XML
    my $resp = $wsdl->first_action(first_thing => 'test');
    is $resp, 2, "get result back";
}


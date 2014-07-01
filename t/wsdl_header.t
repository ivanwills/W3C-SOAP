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
    location      => $dir->file('in_header.wsdl').'',
    module        => 'MyApp::Headers',
    template      => $template,
    lib           => $dir->subdir('lib').'',
    ns_module_map => {
        'urn:HeaderTest'     => 'MyApp::HeaderTest',
    },
);

parser();

ok $parser, "Got a parser object";
isa_ok $parser->document, "W3C::SOAP::WSDL::Document", 'document';
is $parser->document->target_namespace, 'urn:HeaderTest', "Get target namespace";
is scalar( @{ $parser->document->messages }      ),3,"got the right number of messages";
ok scalar( @{ $parser->document->schemas }  ), "Got some schemas";
ok scalar( @{ $parser->document->port_types } ), "Got some port types";
ok scalar(@{ $parser->document->services }), "got some services";

my $service = $parser->document->services->[0];
is $service->name, "HeaderTestService", "got the service expected";
ok scalar(@{$service->ports}), "Got some ports";
my $port = $service->ports->[0];
is $port->name, "HeaderTestSoap", "got the right port";
ok scalar(@{ $port->binding->operations }), "got some operations";
my $operation = $port->binding->operations->[0];
isa_ok $operation, "W3C::SOAP::WSDL::Document::Operation", 'operation';
is $operation->name, "OpGet", "and got the right operation";
is $operation->action(), 'urn:HeaderTest/OpGet', "got the right action";
is $operation->style(), 'document',"got the right style";


ok scalar(@{$operation->inputs}), "got some inputs";
my $input = $operation->port_type->inputs->[0];


isa_ok $input, "W3C::SOAP::WSDL::Document::InOutPuts";
ok $input->message, "got message";


ok $input->header, "got a header";
isa_ok $input->header, 'W3C::SOAP::WSDL::Document::Message', 'header';

is $input->header->element->perl_name, 'authentication_info', "got the perl name we expected";

ok my $class_name = $parser->dynamic_classes(), "dynamic_classes";

ok my $object = $class_name->new(), "make an object";

ok my $meth = $object->meta()->get_method('op_get'), "get the method metaclass";
ok $meth->has_in_header_attribute(), "has in header attribute";
is $meth->in_header_attribute(), 'authentication_info', "and it is what was expected";
ok my $header_class = $meth->in_header_class(), "get in_header_class";
can_ok $header_class, $meth->in_header_attribute();


done_testing();
exit;

sub parser {


}


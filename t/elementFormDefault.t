#!/usr/bin/perl

use strict;
use warnings;
use Test::More;
use Path::Class;
use Data::Dumper qw/Dumper/;
use File::ShareDir qw/dist_dir/;
use Template;
use W3C::SOAP::XSD::Parser;
use XML::LibXML;
use lib file($0)->parent->subdir('lib').'';

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
    location      => $dir->file('elementFormDefault-qualified.xsd').'',
    template      => $template,
    lib           => $dir->subdir('lib').'',
    ns_module_map => {},
    module_base   => 'ElementFormDefault',
);

my (@classes) = sort eval { $parser->write_modules };
ok !$@, "Create dynamic classes correctly"
    or BAIL_OUT($@);

for my $class (@classes) {
    my $file = "$class.pm";
    $file =~ s{::}{/}g;
    require $file;
}

dynamic_modules(@classes);
done_testing();
exit;

sub dynamic_modules {
    my ($qual, $unqual) = @_;

    my $unobject = $unqual->new(
        process_record => {
            base           => 'TEST',
            timestamp      => '2013-08-26T00:00:00',
            correlation_id => '1234',
            billing_id     => '4321',
        }
    );

    ok $unobject, 'Get a new unobject';
    ok $unobject->process_record, 'Currectly set element';
    is $unobject->process_record->base, 'TEST', 'Currectly set element';

    my $xml = XML::LibXML->load_xml(string => <<'XML');
<?xml version="1.0" encoding="UTF-8"?>
<soapenv:Envelope xmlns:soapenv="http://schemas.xmlsoap.org/soap/envelope/">
    <soapenv:Body/>
</soapenv:Envelope>
XML

    my ($xml_str) = $unobject->to_xml($xml);
    note "$xml_str\n", Dumper $unobject->to_data;
    like $xml_str, qr/<base>/, 'The base attribute has no namespace prefix';

    eval {
        my $object = $qual->new(
            re_process_record => {
                base           => 'TEST',
                timestamp      => '2013-08-26T00:00:00',
                correlation_id => '1234',
                billing_id     => '4321',
            }
        );

        ok $object, 'Get a new object';
        ok $object->re_process_record, 'Currectly set element';
        is $object->re_process_record->base, 'TEST', 'Currectly set parent base element';
        is $object->re_process_record->billing_id, '4321', 'Currectly set this base element';

        my ($xml_str) = $object->to_xml($xml);
        note $xml_str;
        like $xml_str, qr/<base>/, 'The base attribute has no namespace prefix';
        like $xml_str, qr/<\w+:billingId>/, 'The billingId attribute has a namespace prefix';
    };
    my $e = $@;
    ok !$e, 'No errors parsing complex content value';
    diag $e;
}


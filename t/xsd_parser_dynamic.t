#!/usr/bin/perl

use strict;
use warnings;
use Test::More;
use Path::Class;
use Data::Dumper qw/Dumper/;
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
    $class = 'Dynamic::XSD::urn::eg_schema_org';

    my %test_data = (
        el1   => '1234',
        el2   => 1234,
        el2_5 => 1,
        el3   => 'abcd',
        el4   => {
            first_thing => 'a string',
            second_thing => 'SUCCESS',
        },
        el5 => {
            first_thing => 'another string',
            second_thing => 'FAILURE',
        },
        el6 => [
            {
                first_thing  => 'el6 first thing',
                second_thing => 'SUCCESS',
            },
            {
                first_thing  => 'el6 second first thing',
                second_thing => 'FAILURE',
            },
        ],
        el7 => {
            first_thing => '1st',
            choice2    => 'choice no 2',
            last_thing  => 'wooden spoon',
        },
        el8 => {
            first_thing  => '8: 1st',
            third_thing  => '2012-06-14',
            #fourth_thing => 4,
            fith_thing    => '2012-06-14+10:00',
            local_choice3 => 333,
        },
        el9 => {
            other => {
                other_one => 'Other One',
                other_two => 55,
            },
        },
    );
    my $eg = eval {
        $class->new(%test_data)
    };
    #diag Dumper $eg;
    #BAIO_OUT('no more');
    ok !$@, "No error in creating eg object"
        or diag $@;
    isa_ok $eg, $class, 'Get an actual object';

    $test_data{el2_5} = 'true';
    $test_data{el4}   = [$test_data{el4}];
    $test_data{el5}   = [$test_data{el5}];

    local $Data::Dumper::Sortkeys = 1;
    if ( $eg ) {
        is_deeply $eg->to_data(stringify=>1), \%test_data, 'Get out what you put in'
            or diag Dumper $eg->to_data(stringify=>1), \%test_data;
    }
    else {
        ok 0, 'Got no object';
    }

    is ref $eg->el4->[0], 'Dynamic::XSD::urn::parent_schema_org::complexThing', 'Get a list of objects';

    my $xml = XML::LibXML->load_xml(string => <<'XML');
<?xml version="1.0" encoding="UTF-8"?>
<soapenv:Envelope xmlns:soapenv="http://schemas.xmlsoap.org/soap/envelope/">
    <soapenv:Body/>
</soapenv:Envelope>
XML

    my @str = eval { $eg->to_xml($xml) };
    ok !$@, "Convert to XML ok"
        or diag $@;
    like $str[-1]->toString, qr/urn:other.schema.org/, 'Contains a sub namespace reference';
    #note join "\n", map {$_->toString} @str;
    is $str[2]->toString,
        '<WSX0:el2_5 xmlns:WSX0="urn:eg.schema.org">true</WSX0:el2_5>',
        'Boolean value is searalized correctly';
}

sub dynamic_modules_alias {
    note my ($class) = @_;
    $class = 'Dynamic::XSD::urn::eg_schema_org';

    my %test_data = (
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
        el6 => [
            {
                firstThing  => 'el6 first thing',
                secondThing => 'SUCCESS',
            },
            {
                firstThing  => 'el6 second first thing',
                secondThing => 'FAILURE',
            },
        ],
        el7 => {
            firstThing => '1st',
            choice2    => 'choice no 2',
            lastThing  => 'wooden spoon',
        },
        el8 => {
            first_thing  => '8: 1st',
            third_thing  => '2012-06-14',
            #fourth_thing => 4,
            fith_thing    => '2012-06-14+10:00',
            local_choice3 => 333,
        },
    );
    my $eg = eval {
        $class->new(%test_data)
    };
    ok !$@, "No error in creating eg object"
        or diag $@;
    isa_ok $eg, $class, 'Get an actual object';

    $test_data{el6}[0]{first_thing}  = $test_data{el6}[0]{firstThing};
    $test_data{el6}[0]{second_thing} = $test_data{el6}[0]{secondThing};
    $test_data{el6}[1]{first_thing}  = $test_data{el6}[1]{firstThing};
    $test_data{el6}[1]{second_thing} = $test_data{el6}[1]{secondThing};
    $test_data{el7}{first_thing}     = $test_data{el7}{firstThing};
    $test_data{el7}{last_thing}      = $test_data{el7}{lastThing};
    delete $test_data{el6}[0]{firstThing};
    delete $test_data{el6}[0]{secondThing};
    delete $test_data{el6}[1]{firstThing};
    delete $test_data{el6}[1]{secondThing};
    delete $test_data{el7}{firstThing};
    delete $test_data{el7}{lastThing};
    $test_data{el4} = [$test_data{el4}];
    $test_data{el5} = [$test_data{el5}];
    $test_data{el8}{third_thing} = '2012-06-14T00:00:00';
    $test_data{el8}{fith_thing}  = '2012-06-14T00:00:00';

    local $Data::Dumper::Sortkeys = 1;
    if ( $eg ) {
        is_deeply $eg->to_data(stringify=>1), \%test_data, 'Get out what you put in'
            or diag Dumper $eg->to_data(stringify=>1), \%test_data;
    }
    else {
        ok 0, 'Got no object';
    }
}


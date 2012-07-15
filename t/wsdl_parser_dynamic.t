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
    can_ok $class, 'first_action';
    $class->first_action;
}


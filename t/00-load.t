#!/usr/bin/perl

use strict;
use warnings;
use Test::More;
#use Test::NoWarnings;
use Path::Class;

my @modules = get_modules();

plan  tests => @modules + 0;

for my $module (@modules) {
    use_ok($module);
}

diag( "Testing W3C::SOAP::XSD::VERSION, Perl $], $^X" );

sub get_modules {
    my @files = file($0)->parent->parent->subdir('lib')->children;
    my @modules;

    while (my $file = shift @files) {
        if ( -d $file ) {
            push @files, $file->children;
        }
        elsif ( $file =~ /[.]pm$/ ) {
            my $module = $file;
            $module =~ s/.*lib\///;
            $module =~ s/\//::/gxms;
            $module =~ s/[.]pm//;
            push @modules, $module;
        }
    }

    return @modules;
}

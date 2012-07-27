#!/usr/bin/perl

use strict;
use warnings;
use Test::More;
use Path::Class;
use Data::Dumper qw/Dumper/;
use File::ShareDir qw/dist_dir/;
use Template;
use W3C::SOAP qw/load_wsdl/;
use WWW::Mechanize;

my $dir = file($0)->parent;
my $wsdls = $dir->file('wsdls.txt')->openr;

plan( skip_all => 'Test can only be run if test directory is writable' ) if !-w $dir;

# set up templates
my $mech = WWW::Mechanize->new;
$mech->timeout(2);
my $count = 1;

while (my $wsdl = <$wsdls>) {
    next if $wsdl =~ /^#/;
    chomp $wsdl;
    eval {
        $mech->get($wsdl);
        test_wsdl($wsdl);
    };
    last if $count++ > 90;
}
done_testing;

sub test_wsdl {
    my ($wsdl) = @_;

    # create the parser object
    my @cmd = ( qw/perl -MW3C::SOAP=load_wsdl -e/, "load_wsdl(q{$wsdl})" );
    note join ' ', @cmd, "\n";
    my $error = system @cmd;
    ok !$error, "Loaded $wsdl"
        or BAIL_OUT("Error: $error");
    return;
}

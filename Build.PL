use strict;
use warnings;
use Module::Build;

my $builder = Module::Build->new(
    module_name       => 'W3C::SOAP',
    license           => 'perl',
    dist_author       => 'Ivan Wills <ivan.wills@gmail.com>',
    dist_version_from => 'lib/W3C/SOAP/XSD.pm',
    requires          => {
        'perl'                         => 5.008,
        'XML::LibXML'                  => 0,
        'Moose'                        => 1,
        'Moose::Role'                  => 1,
        'Moose::Util::TypeConstraints' => 1,
        'MooseX::Types::XMLSchema'     => 0.03,
        'File::ShareDir'               => 1.0,
        'Module::Build'                => 0.3,
        'Path::Class'                  => 0.1,
        'Template'                     => 2.2,
        'WWW::Mechanize'               => 1.6,
        'XML::LibXML'                  => 1.7,
        'MooseX::Exception::Base'      => 0,
        'TryCatch'                     => 1.0,
        'DateTime'                     => 0,
        'DateTime::Format::Strptime'   => 0,
        'MooseX::Types'                => 0,
        'namespace::autoclean'         => 0,
    },
    recommends => {
        'MooseX::Aliases' => 0,
    },
    build_requires => {
        'Test::More'       => 0,
        'Test::NoWarnings' => 0,
    },
    share_dir => {
        dist => [
            'templates',
        ],
    },
    add_to_cleanup     => [ 'W3C-SOAP-*' ],
    create_makefile_pl => 'traditional',
    #create_license     => 1,
    meta_merge => {
        resources => {
            repository => 'git://github.com/ivanwills/W3C-SOAP.git',
            bugtracker => 'http://rt.cpan.org/NoAuth/Bugs.html?Dist=W3C::SOAP',
        },
    },
);

$builder->create_build_script();

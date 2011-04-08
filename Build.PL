
use strict;
use warnings;

use Module::Build 0.3601;


my %module_build_args = (
  'build_requires' => {
    'Exporter' => '0',
    'File::Spec' => '0',
    'FindBin' => '0',
    'Module::Build' => '0.3601',
    'Test::More' => '0',
    'constant' => '0'
  },
  'configure_requires' => {
    'Module::Build' => '0.3601'
  },
  'dist_abstract' => 'Use any version of JSON RPC over any libwww supported transport protocols.',
  'dist_author' => [
    'Brad Gilbert <b2gills@gmail.com>'
  ],
  'dist_name' => 'JSON-RPC-LWP',
  'dist_version' => '0.006',
  'license' => 'perl',
  'module_name' => 'JSON::RPC::LWP',
  'recommends' => {},
  'recursive_test_files' => 1,
  'requires' => {
    'JSON::RPC::Common' => '0',
    'LWP::UserAgent' => '0',
    'Moose' => '0',
    'URI' => '1.58',
    'namespace::clean' => '0.20',
    'perl' => '5.008'
  },
  'script_files' => []
);


my $build = Module::Build->new(%module_build_args);

$build->create_build_script;

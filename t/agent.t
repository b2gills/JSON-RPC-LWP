use warnings;
use strict;

use Test::More;

use JSON::RPC::LWP;
my $package = 'JSON::RPC::LWP';
my $dist    = 'JSON-RPC-LWP';
my $version = $JSON::RPC::LWP::VERSION;
my $default = "JSON-RPC-LWP/$version";

use File::Spec;
use FindBin;
use lib File::Spec->catdir($FindBin::Bin,'lib');

use Util;

# [ $agent_in, $agent_full ],
my @test = (
  [ undef, $default ],
  [ 'testing' ],
  [ '' ],
  [ ' ', " $default" ],
  [ 'testing ', "testing $default" ],
  [ $default ],
  [ $package ],
  [ $dist ],
);

my $init_count = test_on_initialize_count + test_after_initialize_count;
plan tests => 4 + @test * $init_count;

{
  my $rpc = JSON::RPC::LWP->new( _agent => 'anything' );
  is $rpc->_agent,     $default, '_agent is initialized correctly';
}

{
  my $rpc = JSON::RPC::LWP->new;
  is $rpc->agent,      $default, 'Default agent';
}

for my $test (@test){
  my($init,$full) = @$test;

  test_on_initialize(    $package, $default, $init, $full );
  test_after_initialize( $package, $default, $init, $full );
}


subtest 'sub classing with version' => sub{
  print "\n";
  note 'sub classing JSON::RPC::LWP with $VERSION';
  {
    package MY::Test;
    our @ISA = 'JSON::RPC::LWP';
    our $VERSION = '0.001';
  }
  my $parent_package = $package;
  my $package = 'MY::Test';
  my $version = $MY::Test::VERSION;
  my $init_agent = "$package/$version";

  my @test = (
    [ undef, $init_agent ],
    [ 'testing' ],
    [ '' ],
    [ ' ', " $init_agent" ],
    [ 'testing ', "testing $init_agent" ],
    [ $init_agent ],
    [ $package ],
    [ $parent_package ],
    [ $dist ],
  );

  plan tests => 4 + @test * $init_count;

  my $test = new_ok $package;
  isa_ok $test, $parent_package;
  is
    $test->_agent,
    $init_agent,
    'the ->_agent attribute is initialized with the new classname';
  is
    $test->agent,
    $init_agent,
    'the ->agent attribute is initialized with the new classname';

  for my $test (@test){
    my($init,$full) = @$test;

    test_on_initialize(    $package, $init_agent, $init, $full );
    test_after_initialize( $package, $init_agent, $init, $full );
  }
};

subtest 'sub classing without version' => sub{
  print "\n";
  note 'sub classing JSON::RPC::LWP without $VERSION';
  {
    package MY::Test::NoVersion;
    our @ISA = 'JSON::RPC::LWP';
  }
  my $parent_package = $package;
  my $package = 'MY::Test::NoVersion';
  my $version;
  my $init_agent = $package;

  my @test = (
    [ undef, $init_agent ],
    [ 'testing' ],
    [ '' ],
    [ ' ', " $init_agent" ],
    [ 'testing ', "testing $init_agent" ],
    [ $init_agent ],
    [ $package ],
    [ $parent_package ],
    [ $dist ],
  );

  plan tests => 4 + @test * $init_count;

  my $test = new_ok $package;
  isa_ok $test, $parent_package;
  is
    $test->_agent,
    $init_agent,
    'the ->_agent attribute is initialized with the new classname';
  is
    $test->agent,
    $init_agent,
    'the ->agent attribute is initialized with the new classname';

  for my $test (@test){
    my($init,$full) = @$test;

    test_on_initialize(    $package, $init_agent, $init, $full );
    test_after_initialize( $package, $init_agent, $init, $full );
  }
};

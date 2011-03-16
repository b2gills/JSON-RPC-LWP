use warnings;
use strict;

use Test::More;

use JSON::RPC::LWP;
my $package = 'JSON::RPC::LWP';
my $dist    = 'JSON-RPC-LWP';
my $version = $JSON::RPC::LWP::VERSION;
my $default = "JSON-RPC-LWP/$version";

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

plan tests => 3 + @test * 2;

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

sub test_on_initialize{
  my( $package, $default, $init, $full ) = @_;
  $full = $init unless defined $full;

  my $initquote = defined $init ? qq["$init"] : 'undef';
  my $fullquote = defined $init ? qq["$full"] : 'undef';

  subtest qq[initialize agent to $initquote], sub{
    print "\n";
    note  qq[initialize agent to $initquote];
    no warnings 'uninitialized';
    plan tests => 3;

    note qq[$package->new( agent => $initquote )];
    my $rpc = $package->new( agent => $init );

    is $rpc->agent,       $full, 'rpc->agent';
    is $rpc->ua->agent.'', $full, 'rpc->ua->agent';
    is $rpc->marshal->user_agent, $full, 'rpc->marshal->user_agent';
  };
}

sub test_after_initialize{
  my( $package, $default, $init, $full ) = @_;
  $full = $init unless defined $full;

  my $initquote = defined $init ? qq["$init"] : 'undef';
  my $fullquote = defined $init ? qq["$full"] : 'undef';

  subtest qq[set agent to $initquote after initialization], sub{
    print "\n";
    note  qq[set agent to $initquote after initialization];
    no warnings 'uninitialized';
    plan tests => 4;

    note qq[$package->new()];
    my $rpc = $package->new();

    is $rpc->agent, $default, 'initialized with default';
    note qq[rpc->agent( $initquote ) ];
    $rpc->agent($init);

    is $rpc->agent,        $full, 'rpc->agent';
    is $rpc->ua->agent.'', $full, 'rpc->ua->agent';
    is $rpc->marshal->user_agent, $full, 'rpc->marshal->user_agent';
  };
}

subtest 'sub classing' => sub{
  note 'sub classing JSON::RPC::LWP';
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

  plan tests => 4 + @test * 2;

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

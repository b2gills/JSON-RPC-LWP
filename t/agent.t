use warnings;
use strict;

use Test::More;

use JSON::RPC::LWP;
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
  [ 'JSON-RPC-LWP' ]
);

plan tests => 2 + @test * 2;

subtest '_agent' , sub{
  plan tests => 1;
  my $rpc = JSON::RPC::LWP->new( _agent => 'anything' );
  is $rpc->_agent,     $default, '_agent is initialized correctly';
};

subtest 'Defaults', sub{
  plan tests => 1;
  my $rpc = JSON::RPC::LWP->new;
  is $rpc->agent,      $default, 'Default agent';
};

for my $test (@test){
  my($init,$full) = @$test;
  $full = $init unless defined $full;

  my $initquote = defined $init ? qq["$init"] : 'undef';
  my $fullquote = defined $init ? qq["$full"] : 'undef';

  subtest qq[initialize agent to $initquote], sub{
    no warnings 'uninitialized';
    plan tests => 3;

    note qq[JSON::RPC::LWP->new( agent => $initquote )];
    my $rpc = JSON::RPC::LWP->new( agent => $init );

    is $rpc->agent,       $full, 'rpc->agent';
    is $rpc->ua->agent.'', $full, 'rpc->ua->agent';
    is $rpc->marshal->user_agent, $full, 'rpc->marshal->user_agent';
  };
  subtest qq[set agent to $initquote after initialization], sub{
    no warnings 'uninitialized';
    plan tests => 4;

    note qq[JSON::RPC::LWP->new()];
    my $rpc = JSON::RPC::LWP->new();

    is $rpc->agent, $default, 'initialized with default';
    note qq[rpc->agent( $initquote ) ];
    $rpc->agent($init);

    is $rpc->agent,        $full, 'rpc->agent';
    is $rpc->ua->agent.'', $full, 'rpc->ua->agent';
    is $rpc->marshal->user_agent, $full, 'rpc->marshal->user_agent';
  };
}

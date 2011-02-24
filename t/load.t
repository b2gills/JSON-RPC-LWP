use warnings;
use strict;

use Test::More tests => 5;

require_ok('JSON::RPC::LWP');

my $rpc = JSON::RPC::LWP->new;
ok $rpc, '->new';
is $rpc->count, 0, '->count starts at 0';

use FindBin;

# file:// transport does't handle POST requests
$rpc->prefer_get(1);

my $error = $rpc->call("file://${FindBin::Bin}/error.json",'test');
ok exists $error->{error}, 'test for returned errors';

my $fine = $rpc->call("file://${FindBin::Bin}/fine.json",'test');
ok ! exists $fine->{error}, 'test for normal return value';

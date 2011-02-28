use warnings;
use strict;

use Test::More tests => 5;

require_ok('JSON::RPC::LWP');

my $rpc = new_ok 'JSON::RPC::LWP';
is $rpc->count, 0, '->count starts at 0';

use FindBin;
use File::Spec;

# file:// transport does't handle POST requests
$rpc->prefer_get(1);

my $error_file = File::Spec->catfile($FindBin::Bin,'error.json');
my $fine_file  = File::Spec->catfile($FindBin::Bin,'fine.json');

my $error_text =
qq[{"jsonrpc":"2.0","error":{"data":null,"message":"error","code":101},"id":1}\n];
my $fine_text = qq[{"jsonrpc":"2.0","id":2,"result":"fine"}\n];

SKIP: {
  open my $err_fh, '>', $error_file
    or skip "error creating $error_file", 1;

  print {$err_fh} $error_text
    or skip "error printing to $error_file", 1;

  close $err_fh
    or skip "error closing $error_file", 1;

  my $error = $rpc->call("file://${FindBin::Bin}/error.json",'test');
  ok $error->has_error, 'test for returned errors';
}
SKIP: {
  open my $err_fh, '>', $fine_file
    or skip "error creating $fine_file", 1;

  print {$err_fh} $fine_text
    or skip "error printing to $fine_file", 1;

  close $err_fh
    or skip "error closing $fine_file", 1;

  my $fine = $rpc->call("file://${FindBin::Bin}/fine.json",'test');
  ok $fine->has_result, 'test for normal return value';
}

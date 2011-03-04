package JSON::RPC::LWP;
use 5.008;
use URI 1.58;
use LWP::UserAgent;
use JSON::RPC::Common;
use JSON::RPC::Common::Marshal::HTTP; # uses Moose

use Moose::Util::TypeConstraints;

# might as well use it, it gets loaded anyway
use JSON::RPC::Common::TypeConstraints qw(JSONValue);

subtype 'JSON.RPC.Version'
  => as 'Str'
  => where {
    $_ eq '1.0' ||
    $_ eq '1.1' ||
    $_ eq '2.0'
};

coerce 'JSON.RPC.Version'
  => from 'Int',
  => via sub{
    $_.'.0'
  }
;

use namespace::clean;
use Moose;

has agent => (
  is => 'rw',
  isa => 'Maybe[Str]',
  default => sub{
    my($self) = @_;
    $self->_agent;
  },
  trigger => sub{
    my($self,$agent) = @_;
    unless( defined $agent ){
      $agent = $self->_agent;
    }
    if( length $agent ){
      if( substr($agent,-1) eq ' ' ){
        $agent .= $self->_agent;
      }
    }
    $self->{agent} = $agent;
    $self->ua->agent($agent);
    $self->marshal->user_agent($agent);
  }
);

{ no strict 'vars';
has _agent => (
  is => 'ro',
  isa => 'Str',
  default => "JSON-RPC-LWP/$VERSION",
  init_arg => undef,
);
}

my @ua_handles = qw{
  timeout
  proxy
  no_proxy
  env_proxy
  from
  credentials
};

has ua => (
  is => 'rw',
  isa => 'LWP::UserAgent',
  default => sub{
    my $lwp = LWP::UserAgent->new(
      env_proxy => 1,
      keep_alive => 1,
      parse_head => 0,
    );
  },
  handles => \@ua_handles,
);

my @marshal_handles = qw{
  prefer_get
  rest_style_methods
  prefer_encoded_get
};

has marshal => (
  is => 'rw',
  isa => 'JSON::RPC::Common::Marshal::HTTP',
  default => sub{
    JSON::RPC::Common::Marshal::HTTP->new;
  },
  handles => \@marshal_handles,
);

my %from = (
  map( { $_, 'ua' } @ua_handles ),
  map( { $_, 'marshal' } @marshal_handles ),
);

sub BUILD{
  my($self,$args) = @_;

  while( my($key,$value) = each %$args ){
    if( exists $from{$key} ){
      my $attr = $from{$key};
      $self->$attr->$key($value);
    }
  }
}

has version => (
  is => 'rw',
  isa => 'JSON.RPC.Version',
  default => '2.0',
  coerce => 1,
);

has previous_id => (
  is => 'ro',
  isa => JSONValue,
  init_arg => undef,
  writer => '_previous_id',
  predicate => 'has_previous_id',
  clearer => 'clear_previous_id',
);

# default id generator is a simple incrementor
my $default_id_gen = sub{
  my($self,$prev) = @_;
  $prev ||= 0;
  return $prev + 1;
};

has id_generator => (
  is => 'rw',
  isa => 'CodeRef',
  default => sub{ $default_id_gen },
);

sub call{
  my($self,$uri,$method,@rest) = @_;

  $uri = URI->new($uri) unless blessed $uri;

  my $params;
  if( @rest == 1 and ref $rest[0] ){
    ($params) = @rest;
  }else{
    $params = \@rest;
  }
  $self->{count}++;

  my $next_id;
  if( $self->has_previous_id ){
    $next_id = $self->id_generator->($self);
  }else{
    $next_id = $self->id_generator->($self,$self->previous_id);
  }
  $self->_previous_id($next_id);

  my $request = $self->marshal->call_to_request(
    JSON::RPC::Common::Procedure::Call->inflate(
      jsonrpc => $self->version,
      id      => $next_id,
      method  => $method,
      params  => $params,
    ),
    uri => $uri,
  );
  my $response = $self->ua->request($request);
  my $result = $self->marshal->response_to_result($response);

  return $result;
}

sub notify{
  my($self,$uri,$method,@rest) = @_;

  $uri = URI->new($uri) unless blessed $uri;

  my $params;
  if( @rest == 1 and ref $rest[0] ){
    $params = $rest[0];
  }else{
    $params = \@rest;
  }
  $self->{count}++;

  my $request = $self->marshal->call_to_request(
    JSON::RPC::Common::Procedure::Call->inflate(
      jsonrpc => $self->version,
      method  => $method,
      params  => $params,
    ),
    uri => $uri,
  );
  my $response = $self->ua->request($request);

  return $response;
}

no Moose;
__PACKAGE__->meta->make_immutable;
1;
#ABSTRACT: Use any version of JSON RPC over any libwww supported transport protocols.
=head1 SYNOPSIS

    use JSON::RPC::LWP;

    my $rpc = JSON::RPC::LWP->new;
    $rpc->from('name@address.com');
    $rpc->agent('JSON::RPC::LWP Example');

    my $login = $rpc->call(
      'https://us1.lacunaexpanse.com/empire', # uri
      'login', # service
      [$empire,$password,$api_key] # JSON container
    );

=head1 METHODS

=over 4

=item C<< call( $uri, $method ) >>

=item C<< call( $uri, $method, {...} ) >>

=item C<< call( $uri, $method, [...] ) >>

=item C<< call( $uri, $method, param1, param2, ... ) >>

Initiate a L<JSON::RPC::Common::Procedure::Call>

Uses L<LWP::UserAgent> for transport.

Then returns a L<JSON::RPC::Common::Procedure::Return>

=item C<< notify( $uri, $method ) >>

=item C<< notify( $uri, $method, {...} ) >>

=item C<< notify( $uri, $method, [...] ) >>

=item C<< notify( $uri, $method, param1, param2, ... ) >>

Initiate a L<JSON::RPC::Common::Procedure::Call>

Uses L<LWP::UserAgent> for transport.

Basically this is the same as a call, except without the C<id> key,
and doesn't expect a JSON RPC result.

Returns the L<HTTP::Response> from L<C<ua>|LWP::UserAgent>.

To check for an error use the C<is_error> method of the returned
response object.

=back

=head1 ATTRIBUTES

=over 4

=item C<previous_id>

Returns the previous id used in the C<call()> method.

=item C<has_previous_id>

Returns true if the C<previous_id> has any value associated with it.

=item C<clear_previous_id>

Clears the previous id, useful for generators that do something different
the first time they are used.

=item C<id_generator>

This is used for generating the next id to be used in the C<call()> method.

The default is just an incrementing subroutine.

The call-back gets called with 1 or 2 arguments.

The first is the object which is calling it.

The secound is the previous id, if the object has one.

The C<previous_id> attribute gets set to the return value of the call-back
B<before> the call actually goes through

The reason for this attribute, is to make it easy to change the order
of the id's that get used.

=item C<version>

The JSON RPC version to use. one of 1.0 1.1 or 2.0

=item C<agent>

Get/set the product token that is used to identify the user agent on the network.
The agent value is sent as the "User-Agent" header in the requests.
The default is the string returned by the C<_agent> attribute (see below).

If the agent ends with space then the C<_agent> string is appended to it.

The user agent string should be one or more simple product identifiers
with an optional version number separated by the "/" character.

Setting this will also set C<< ua->agent >> and C<< marshal->user_agent >>.

=item C<_agent>

Returns the default agent identifier.
This is a string of the form "JSON-RPC-LWP/#.###", where "#.###" is
substituted with the version number of this library.

=item C<marshal>

An instance of L<JSON::RPC::Common::Marshal::HTTP>.
This is used to convert from a L<JSON::RPC::Common::Procedure::Call>
to a L<HTTP::Request>,
and from an L<HTTP::Response> to a L<JSON::RPC::Common::Procedure::Return>.

B<Attributes delegated to C<marshal>>

=over 4

=item C<prefer_get>

=item C<rest_style_methods>

=item C<prefer_encoded_get>

=back

=item C<ua>

An instance of L<LWP::UserAgent>.
This is used for the transport layer.

B<Attributes delegated to C<ua>>

=over 4

=item C<timeout>

=item C<proxy>

=item C<no_proxy>

=item C<env_proxy>

=item C<from>

=item C<credentials>

=back

=back

=for Pod::Coverage BUILD

=cut

package JSON::RPC::LWP;
BEGIN {
  $JSON::RPC::LWP::VERSION = '0.002';
}
use URI;
use LWP::UserAgent;
use JSON::RPC::Common;
use JSON::RPC::Common::Marshal::HTTP; # uses Moose

use namespace::clean;
use Moose;

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
  handles => [qw'
    agent
    _agent
    timeout
    proxy
    no_proxy
    env_proxy
    from
    credentials
  '],
);

has marshal => (
  is => 'rw',
  isa => 'JSON::RPC::Common::Marshal::HTTP',
  default => sub{
    JSON::RPC::Common::Marshal::HTTP->new;
  },
  handles => [qw'
    prefer_get
    rest_style_methods
    prefer_encoded_get
  '],
);

has count => (
  is => 'ro',
  isa => 'Int',
  default => 0,
);
sub reset_count{
  $_[0]->{count} = 0;
}

has version => (
  is => 'rw',
  isa => 'Num',
  default => '2.0',
  # should probably replace this trigger with a subtype
  trigger => sub{
    my($self,$new,$old) = @_;
    $new = 1 if $new < 1;
    $self->{version} = sprintf '%3.1f', $new;
  },
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

  my $request = $self->marshal->call_to_request(
    JSON::RPC::Common::Procedure::Call->inflate(
      jsonrpc => $self->version,
      id      => ++$self->{count},
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

__END__
=pod

=head1 NAME

JSON::RPC::LWP - Use any version of JSON RPC over any libwww supported transport protocols.

=head1 VERSION

version 0.002

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

=item C<count>

How many times C<call> was called

=item C<reset_count>

Resets C<count>.

=item C<version>

The JSON RPC version to use. one of 1.0 1.1 or 2.0

=item C<marshal>

An instance of L<JSON::RPC::Common::Marshal::HTTP>.
This is used to convert from a L<JSON::RPC::Common::Procedure::Call>
to a L<HTTP::Request>,
and from an L<HTTP::Response> to a L<JSON::RPC::Common::Procedure::Return>.

B<Methods delegated to C<marshal>>

=over 4

=item C<prefer_get>

=item C<rest_style_methods>

=item C<prefer_encoded_get>

=back

=item C<ua>

An instance of L<LWP::UserAgent>.
This is used for the transport layer.

B<Methods delegated to C<ua>>

=over 4

=item C<agent>

=item C<_agent>

=item C<timeout>

=item C<proxy>

=item C<no_proxy>

=item C<env_proxy>

=item C<from>

=item C<credentials>

=back

=back

=head1 AUTHOR

Brad Gilbert <b2gills@gmail.com>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2011 by Brad Gilbert.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut


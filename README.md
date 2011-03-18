# NAME

### JSON::RPC::LWP

Use any version of JSON RPC over any [libwww][] supported transport protocols.

# SYNOPSIS

    use JSON::RPC::LWP;

    my $rpc = JSON::RPC::LWP->new(
      from  => 'name@address.com',
      agent => 'Example ',
    );

    my $login = $rpc->call(
      'https://us1.lacunaexpanse.com/empire', # uri
      'login', # service
      [$empire,$password,$api_key] # JSON container
    );

# REASONING

[JSON::RPC::Common][] provides a useful API for a version, and transport,
agnostic JSON remote procedure calls.
It does not however provide any transport protocol itself.
Instead we use [LWP::UserAgent][] to handle the transport.

This module aims to provide a simple layer over
[JSON::RPC::Common][], and [LWP::UserAgent][] to make
JSON remote procedure calls easy to use.

# REQUIRES

- [JSON::RPC::Common][]
- [LWP::UserAgent][]
- [URI][] 1.58

# LICENSE

This software is copyright&copy; 2011 by Brad Gilbert.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

[JSON::RPC::Common]: http://search.cpan.org/dist/JSON-RPC-Common
[LWP::UserAgent]:    http://search.cpan.org/dist/libwww-perl
[libwww]:            http://search.cpan.org/dist/libwww-perl
[URI]:               http://search.cpan.org/perldoc/URI

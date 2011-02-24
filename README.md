# NAME

### JSON::RPC::LWP

Use any version of JSON RPC over any [libwww][] supported transport protocols.

# REASONING

[JSON::RPC::Common][] provides a useful API for a version, and transport,
agnostic JSON remote procedure calls.

This module aims to provide a simple layer over
[JSON::RPC::Common][], and [LWP::UserAgent][] to make
JSON remote procedure calls easy to use.

# REQUIRES

- [JSON::RPC::Common][]
- [LWP::UserAgent][]

# LICENSE

This software is copyright (c) 2011 by Brad Gilbert.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

[JSON::RPC::Common]: http://search.cpan.org/dist/JSON-RPC-Common
[LWP::UserAgent]:    http://search.cpan.org/dist/libwww-perl
[libwww]:            http://search.cpan.org/dist/libwww-perl

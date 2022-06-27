#!/usr/bin/env perl

use strict;
use warnings;
use FindBin;
use lib "$FindBin::Bin/lib";
use TeamDX::Server;

my $server = TeamDX::Server->new(
    {
        'server_port' => 3232,
        'debug'       => 1,
    }
);

$server->start();




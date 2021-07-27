#!/user/bin/env perl

use strict;
use warnings;
use FindBin;
use lib "$FindBin::Bin/lib";
use TeamDX::Server;
use sigtrap qw/handler signal_handler normal-signals/;


my $server = TeamDX::Server->new({
                    'server_port' =>3232,
                });

$server->start();


sub signal_handler {
    $server->{sock}->close;
    die "Caught interrupt, $! \n";
    sleep(1);
}

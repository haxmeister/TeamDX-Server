package TeamDX::Server;

use strict;
use warnings;
use IO::Socket::INET;
use IO::Select;
use JSON;
use Term::ANSIColor;
use TeamDX::Dispatcher;
use TeamDX::User;
use Data::Dumper;
$| = 1;

# no server crashes due to sigpipe (client closes unexpectedly)
$SIG{'PIPE'} = 'IGNORE';

sub new {
    my ( $class, $args ) = @_;
    my $self = bless {
        'server_port' => $args->{'server_port'},
        'debug'       => $args->{'debug'},
        'dispatch'    => undef,
        'poll'        => undef,
        'json'        => undef,
        'users'       => [],
        'sock'        => undef,
        'eol'         => "\r\n",
        'recBuf'      => undef,
    }, $class;

    $self->init();
}

sub init {
    my $self = shift;

    # prepare the dispatcher to manage messages
    $self->{dispatch} = TeamDX::Dispatcher->new( { 'server' => $self, } ) || die $!,

      # make a json translator object
      $self->{json} = JSON->new();

    # make a select object to allow for async polling of sockets
    $self->{poll} = IO::Select->new();

    # start listening on the port
    $self->{sock} = IO::Socket::INET->new(
        Listen    => 5,
        LocalAddr => '0.0.0.0',
        LocalPort => $self->{'server_port'},
        Proto     => 'tcp',
        ReusePort => 1,
        Blocking  => 0,
    ) || die "cannot create socket $!";

    # turn on autoflush (no buffering on the socket)
    $self->{sock}->autoflush(1);

    # add our listening socket to select polling also
    $self->{poll}->add( $self->{sock} );

    $self->log_this("Listening for new connections on port $self->{server_port}");
    return $self;
}

sub start {
    my $self = shift;
    my $data;
    my $bytes;

    while (1) {

        # deal with sockets that are ready to be read
        my @readables = $self->{poll}->can_read(5);

        foreach my $handle (@readables) {

            # catch new client connections
            if ( $handle eq $self->{sock} ) {
                $self->new_client( $self->{sock}->accept );
            }
            else {

                # receive messages from already connected clients
                $bytes = sysread( $handle, $data, 5000000 );

                if ( $bytes > 0 ) {
                    chomp($data);
                    $self->multi_line_dispatch( $handle, $data );

                }

                if ( !$bytes ) {
                    $self->remove_user($handle);
                }

            }
        }

        $self->maintenance();
    }
}

sub new_client {
    my $self = shift;
    my $sock = shift;

    $sock->autoflush(1);
    $self->{poll}->add($sock);
    $self->log_this( "New client connected at " . $sock->peerhost . ":" . $sock->peerport );
}

sub broadcast {
    my $self = shift;
    my $data = shift;
    my $string;
    my $thisUser;

    eval { $string = encode_json($data); 1; } or return;

    foreach my $handle ( $self->{poll}->can_write(0) ) {
        $thisUser = $self->get_user_from_handle($handle);

        # only broadcast to logged in users
        if ( $thisUser->{isloggedin} ) {

            if ( $self->{debug} ) {
                $self->log_this( "broadcasting to " . $thisUser->{name} . ":  " . $string );
            }

            # send to socket without error or remove the user and connection
            unless ( eval { $handle->send( $string . $self->{eol} ); 1; } ) {
                $self->warn_this( "Removing " . $thisUser->{name} . " due to errors" );
                $self->remove_user( $thisUser->{handle} );
            }
        }
        elsif ( !$thisUser->{isloggedin} ) {
            $self->warn_this( "Skipping " . $handle->peerhost() . ":" . $handle->peerport() . " (not yet logged in).." );
        }
    }
}

sub dispatch {
    my $self       = shift;
    my $handle     = shift;
    my $msg_string = shift;
    my $data;
    my $serverAction;

    eval { $data = decode_json($msg_string); 1; };
    $data or return;
    next unless defined( $data->{serverAction} );

    $serverAction = $data->{serverAction};

    if ( $self->{dispatch}->can($serverAction) ) {
        $self->{dispatch}->$serverAction( $data, $handle );
    }
}

# accepts a handle and returns the user object that it belongs too
# if the handle doesn't match a user in the user list
# it returns a user with the isloggedin key set to 0
sub get_user_from_handle {
    my $self        = shift;
    my $this_handle = shift;

    my $unlogged_user = { 'isloggedin' => 0, };

    foreach my $user ( @{ $self->{users} } ) {
        if ( $user->{handle} eq $this_handle ) {
            return $user;
        }
    }

    # this handle does not belong to a user in the user list
    return $unlogged_user;
}

# accepts a name string as an argument and searches the user list
# returns a ref to a user object that has that name
# returns an empty string if none are found
sub get_user_from_name {
    my $self      = shift;
    my $this_name = shift;

    foreach my $user ( @{ $self->{users} } ) {
        if ( $this_name eq $user->{name} ) {
            return $user;
        }
        else {
            return '';
        }
    }
}

# accepts a handle
# sets user as isloggedin = 0 and removes
# user handle from polling, also closes
# the user's socket, does not alert user of removal
sub remove_user {
    my $self   = shift;
    my $handle = shift;

    # remove handle from select polling
    $self->{poll}->remove($handle);

    # set user to loggedout
    my $this_user = $self->get_user_from_handle($handle);
    $this_user->{isloggedin} = 0;
    $this_user->{handle}     = '';

    # close connection
    $handle->close;
}

sub log_this {
    my $self = shift;
    my $line = shift;

    print color('grey10');
    print STDERR $self->timestamp();
    print color('white');
    print " $line \n";
    print color('reset');

}

sub warn_this {
    my $self = shift;
    my $line = shift;

    print color('grey10');
    print STDERR $self->timestamp();
    print color('bright_red');
    print " $line \n";
    print color('reset');
}

sub timestamp {
    my $self   = shift;
    my @months = qw( Jan Feb Mar Apr May Jun Jul Aug Sep Oct Nov Dec );
    my @days   = qw(Sun Mon Tue Wed Thu Fri Sat Sun);
    my ( $sec, $min, $hour, $mday, $mon, $year, $wday, $yday, $isdst ) = localtime();
    my $month = $mon + 1;
    $year = $year + 1900;
    return "[$month/$mday/$year $hour:$min:$sec]";
}

sub maintenance {
    my $self = shift;

    # find and remove handles with exceptions
    foreach my $handle ( $self->{poll}->has_exception(0) ) {
        $self->remove_user($handle);
        $self->log_this("Maint: removed handle with exceptions");
    }

    # find and remove handles not associated with a user
    foreach my $user ( @{ $self->{users} } ) {
        if ( $user->{handle} ) {
            if ( !$self->{poll}->exists( $user->{handle} ) ) {
                $self->remove_user( $user->{handle} );
                $self->log_this("Maint: removed an unassociated handle");
            }
        }
    }

}

sub debug_msg {
    my $self = shift;
    my $msg  = shift;

    if ( $self->{debug} ) {
        $self->log_this($msg);
    }
}

sub multi_line_dispatch {
    my $self   = shift;
    my $handle = shift;
    my $data   = shift;

    my @lines = split( /\r\n/, $data );
    foreach my $line (@lines) {
        chomp($line);
        $self->dispatch( $handle, $line );
    }
}

1;


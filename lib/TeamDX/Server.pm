package TeamDX::Server;

use strict;
use warnings;
use IO::Socket::INET;
use IO::Select;
use JSON;
use Term::ANSIColor;
use TeamDX::Dispatcher;
use TeamDX::User;

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
        'users'       => undef,
        'sock'        => undef,
        'eol'         => "\r\n",
        'recBuf'      => undef,
    }, $class;

    $self->init();
}

sub init{
    my $self = shift;

    # prepare the dispatcher to manage messages
    $self->{dispatch} = TeamDX::Dispatcher->new({ 'server' => $self, }) || die $!,

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

    while (1) {

        # deal with sockets that are ready to be read
        if ( my @readables = $self->{poll}->can_read(1) ) {
            foreach my $handle (@readables) {

                # catch new client connections
                if ( $handle == $self->{sock} ) {
                    $self->new_client( $self->{sock}->accept );
                }

                # receive messages from already connected clients
                elsif($data = <$handle>){
                    if($self->{debug}){
                        $self->log_this("recieved: $data");
                    }
                # $handle->recv( my $data, 2024 );
                    chomp($data);
                    $self->dispatch( $handle, $data );

                }
            }
        }
    }
        #sleep(1);
}

sub new_client {
    my $self = shift;
    my $sock = shift;
    #my $user = TeamDX::User->new({
        #'handle' => $sock,
    #});
    #push @{$self->{users}}, $user;
    $self->{poll}->add($sock);
    $self->log_this( "New client connected at " . $sock->peerhost . ":" . $sock->peerport );
}

sub broadcast {
    my $self   = shift;
    my $data   = shift;
    my $string;
    my $thisUser;
    eval {$string = encode_json($data);1;} or return;

    foreach my $handle ( $self->{poll}->can_write(0) ) {
        $thisUser = $self->get_user_from_handle($handle);

        # only broadcast to logged in users
        if ($thisUser->{isloggedin}){

            if($self->{debug}){
                $self->log_this("broadcasting to ".$thisUser->{name}.":  ".$string);
            }

            # send to socket without error or remove the user and connection
            unless ( eval { $handle->send( $string . $self->{eol} ); 1; } ) {
                $self->warn_this( "Removing " . $thisUser->{name} . " due to errors" );
                $self->remove_user( $thisUser->{handle} );
            }
        }elsif(! $thisUser->{isloggedin}){
            $self->warn_this(
                "Skipping ".$handle->peerhost().":".$handle->peerport()." (not yet logged in).."
            );
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
        $self->{dispatch}->$serverAction($data,$handle);
    }
}


# accepts a handle and returns the user object that it belongs too
# if the handle doesn't match a user in the user list
# it returns a user with the isloggedin key set to 0
sub get_user_from_handle {
    my $self        = shift;
    my $this_handle = shift;
    my $unlogged_user   = {
        'isloggedin' => 0,
    };

    foreach my $user ( @{$self->{users}} ) {
        if ( $user->{handle} == $this_handle ) {
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
    my $self     = shift;
    my $this_name = shift;

    foreach my $user ( @{$self->{users}} ){
        if ($this_name eq $user->{name}){
            return $user;
        }else{
            return '';
        }
    }
}

# returns a list of all users that are logged in
sub get_loggedin_users {}

# returns a
sub get_all_users {}




# accepts a handle
# sets user as isloggedin = 0 and removes
# user handle from polling, also closes
# the user's socket, does not alert user of removal
sub remove_user {
    my $self   = shift;
    my $handle = shift;
    #my @newUserList;

    # remove handle from select polling
    $self->{poll}->remove( $handle );

    # set user to loggedout
    my $this_user = get_user_from_handle($handle);
    $this_user->{isloggedin} = 0;
    # close connection
    $handle->close;

    # delete user from userlist
    #while (my $user = shift @{$self->{users}}){
        #unless ($user->{handle} == $handle){
            #push (@newUserList, $user);
        #}
    #}
    #push (@{$self->{users}}, @newUserList);
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

sub sendto{
    my $self = shift;
    my $handle = shift;
    my $data = shift;

}
1;


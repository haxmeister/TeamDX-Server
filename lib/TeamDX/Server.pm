package TeamDX::Server;

use strict;
use JSON;
use warnings;
use IO::Socket::INET;
use IO::Socket;
use IO::Multiplex;
use Term::ANSIColor;
use TeamDX::Dispatcher;
use TeamDX::User;
use Data::Dumper;

sub new {
    my ( $class, $args ) = @_;
    my $self = bless {
        'mux'         => IO::Multiplex->new(),
        'server_port' => $args->{'server_port'},
        'debug'       => $args->{'debug'},
        'dispatch'    => undef,
        'json'        => undef,
        'users'       => {},
        'eol'         => "\r\n",
    }, $class;

    # prepare the dispatcher to manage messages
    $self->{dispatch} = TeamDX::Dispatcher->new( { 'server' => $self, } ) || die $!;
    print"dispatcher initialized\n";

    # make a json translator object
    $self->{json} = JSON->new();
    print"json initialized\n";
    return $self;

}

# mux_connection is called when a new connection is accepted.
sub mux_connection {
    my $self = shift;
    my $mux  = shift;
    my $fh   = shift;

    # Construct a new User object
    my $newUser = TeamDX::User->new({
        'server' => $self,
        'mux'    => $mux,
        'fh'     => $fh,
    });

    # Register this User object in the main list of Users
    $self->{users}{$newUser} = $newUser;
    $self->log_this( "New client connected at " . $fh->peerhost . ":" . $fh->peerport );
}

sub listen_on_port{
    my $self = shift;

    my $socket = IO::Socket::INET->new(
        Listen    => 5,
        LocalAddr => '0.0.0.0',
        LocalPort => $self->{'server_port'},
        Proto     => 'tcp',
        ReusePort => 1,
        Blocking  => 0,
    ) || die "cannot create socket $!";

    print "Listening on port ".$self->{'server_port'}."..\n";
    # setup multiplexer to watch server socket for events
    $self->{mux}->listen($socket);

    # set this package as a place to look for mux callbacks
    $self->{mux}->set_callback_object($self);
}

sub start{
    my $self = shift;
    print "in start method\n";
    #open connection and start listening
    $self->listen_on_port();

    #start multiplexer loop
    $self->{mux}->loop;
}

# accepts a hashref and sends it to all users as json msg
sub broadcast {
    my $self = shift;
    my $data = shift;
    my $string = encode_json($data);

    foreach my $user ( $self->userlist() ) {

        # log debugging messages
        if ( $self->{debug} ) {
            #$self->log_this( "broadcasting to " . $user->{name} . ":  " . $string );
            $self->log_this( "broadcasting to " ."someones name". ":  " . $string );
        }

        # send to socket without error or remove the user and connection
        $user->{fh}->send ( encode_json($data)."\r\n");

    }
}

sub userlist{
    my $self = shift;
    return keys( %{ $self->{'users'} } );
}

sub remove_user{
    my $self = shift;
    my $user = shift;

    delete $self->{users}{$user} if exists $self->{users}{$user};
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


sub debug_msg {
    my $self = shift;
    my $msg  = shift;

    if ( $self->{debug} ) {
        $self->log_this($msg);
    }
}


1;


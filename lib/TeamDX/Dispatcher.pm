package TeamDX::Dispatcher;

use strict;
use warnings;

sub new {
    my ( $class, $args ) = @_;
    my $self = bless {
        'server' => $args->{'server'},
    }, $class;

    return $self;
}

# receives a hashref and a user object
# forwards the hashref to the server for broadcasting
sub sendall {
    my $self   = shift;
    my $data   = shift;
    my $user   = shift;

    $data->{result} = 1;
    $self->{server}->broadcast($data);
}

sub login {
    my $self   = shift;
    my $data   = shift;
    my $user   = shift;
    my $msg;

    if ( exists $data->{name} ) {
        $user->{isloggedin} = 1;
        $msg = '{"clientAction":"login","result":1}';
        $user->send( $msg . $self->{server}->{eol} );
        $self->{server}->debug_msg( "sending:  " . $msg );
        $self->{server}->log_this( $user->{name} . " has logged in.." );
    }else {
        $msg = '{"clientAction":"login","result":0, "error":"Can\'t log in without player name"}';
        $user->send( $msg . $self->{server}->{eol} );
        $self->{server}->debug_msg( "sending:  " . $msg );
    }
}

sub logout {
    my $self   = shift;
    my $data   = shift;
    my $user   = shift;

    $self->{server}->remove_user($user);
    $self->{server}->log_this( $data->{name} . " has logged out" );
}

1;

package TeamDX::Dispatcher;

use strict;
use warnings;

sub new {
    my ( $class, $args ) = @_;
    my $self = bless {
        'server'      => $args->{'server'},
    }, $class;

    return $self;
}

sub sendall {
    my $self     = shift;
    my $data     = shift;
    my $handle   = shift;


    $self->{server}->broadcast($data);
}

sub login {
    my $self     = shift;
    my $data     = shift;
    my $handle   = shift;
    my $thisUser = $self->{server}->user_from_handle($handle);

    if($data->{name}){
        $thisUser->{name} = $data->{name};
        $thisUser->{isloggedin} = 1;
        $handle->send('{action:"login", success:1}');
        $self->{server}->log_this( $thisUser->{name}." has logged in \n");
    }else{
        $handle->send('{action:"error", msg:"Can\'t log in without player name"}');
    }
}

sub logout{
    my $self   = shift;
    my $data   = shift;
    my $handle = shift;

    $handle->send('{action:"logout", msg:"Server has closed the connection."}');
    $self->{server}->remove_user($handle);
    $self->{server}->log_this($data->{name}." has logged out");
}
1;

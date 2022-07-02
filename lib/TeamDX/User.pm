package TeamDX::User;

use strict;
use warnings;
use JSON;

sub new {
    my ( $class, $args ) = @_;

    my $self = bless {
        'name'       => $args->{name} || '',
        'mux'        => $args->{mux},
        'server'     => $args->{server},
        'fh'         => $args->{fh},
        'kills'      => '',
        'rank'       => '',
    }, $class;

    # Register the new User object as the callback specifically for
    # this file handle.
    $self->{mux}->set_callback_object( $self, $self->{fh} );
    $self->{server}->log_this("New user connected..");

    return $self;
}

# message received
sub mux_input {
    my $self = shift;
    shift;    # mux not needed
    shift;    # fh not needed
    my $input = shift; # Scalar reference to the input
    while ( $$input =~ s/^(.*?)\r\n// ) {
    $self->{server}->log_this("processing $1");
        $self->process_command($1);
    }
}

sub mux_close {
    my $self = shift;

    # User disconnected;
    $self->{server}->log_this("User ".$self->{name}." disconnected..");
    delete $self->{server}->{users}{$self} if exists $self->{server}->{users}{$self};


}

sub process_command {
    my $self = shift;
    my $cmd  = shift;

    # attempt to successfully decode the json
    my $data;
    if (  eval{$data = decode_json($cmd);1;} ){
        $self->{server}->log_this("$cmd");
        # if there's no action in the message then drop it and move on
        return unless defined( $data->{serverAction} );
        # look for rpc by the same name as serveraction field
        my $serverAction = $data->{serverAction};
        if ( $self->{server}->{dispatch}->can($serverAction) ) {
            $self->{server}->{dispatch}->$serverAction( $data, $self );
            $self->{server}->log_this("dispatch cleared");
        }else{
            # actions with no rpc get the json dumped to stderr
            $self->{server}->log_this("\n command not found \n" . encode_json($data) . "\n\n");
        }
    }
}

# recieves a json encoded string and sends it to this user
sub send{
    my $self = shift;
    my $msg = shift;
    
    print $self->{fh} "$msg";
    $self->{server}->log_this("sent $msg");
}
1;

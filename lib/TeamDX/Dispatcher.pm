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

sub sendall {
    my $self     = shift;
    my $data     = shift;
    my $handle   = shift;

    $data->{result} = 1;
    $self->{server}->broadcast($data);
}

sub login {
    my $self     = shift;
    my $data     = shift;
    my $handle   = shift;
    my $this_user;
    my $msg;

    if(exists $data->{name}){
        $this_user = $self->{server}->get_user_from_name($data->{name});
        if($this_user){
            $this_user->{isloggedin} = 1;
            $this_user->{handle} = $handle;
            $msg = '{"clientAction":"login","result":1}';
            $handle->send(  $msg. $self->{server}->{eol} );

            $self->debug_msg("sending:  ".$msg);

            $self->{server}->log_this( $this_user->{name}." has logged back in..");
        }else{
            $msg = '{"clientAction":"login","result":1}';
            my $user = TeamDX::User->new({
                'handle'     => $handle,
                'name'       => $data->{name},
                'isloggedin' => 1,
            });

            $self->debug_msg("sending:  ".$msg);

            push @{$self->{server}->{users}}, $user;
            $handle->send($msg.$self->{server}->{eol});
            $self->{server}->log_this( $user->{name}." has logged in..");
        }
    }else{
        $msg = '{"clientAction":"login","result":0, "error":"Can\'t log in without player name"}';
        $handle->send($msg.$self->{server}->{eol});

        $self->debug_msg("sending:  ".$msg);
    }
}

sub logout{
    my $self   = shift;
    my $data   = shift;
    my $handle = shift;
    #my $msg ='{clientAction:\"logout\", msg:\"Server has closed the connection.\"}';

    #if($self->{server}->{debug}){
    #    $self->{server}->log_this("sending:  ".$msg);
    #}
    #$handle->send($msg.$self->{server}->{eol});
    $self->{server}->remove_user($handle);
    $self->{server}->log_this($data->{name}." has logged out");
}

sub get_logged_in_users{
    my $self   = shift;
    my $data   = shift;
    my $handle = shift;
    my $msg;
    my %response =(
        'clientAction' => 'list_logged_in_users',
        'user_list'    => undef,
        'result'       => 1,
    );

    foreach my $user ( @{$self->{server}->{users}} ){
        if ($user->{isloggedin}){
            push @{$response{'user_list'}}, $user->{name};
        }
    }

    $msg = encode_json(%response);
    $handle->send($msg.$self->{server}->{eol});
    if($self->{server}->{debug}){
        $self->{server}->log_this("sending:  ".$msg);
    }
}

sub debug_msg{
    my $self = shift;
    my $msg = shift;

    if($self->{server}->{debug}){
        $self->{server}->log_this($msg);
    }
}
1;

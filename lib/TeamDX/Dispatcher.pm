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


    $self->{server}->broadcast($data);
}

sub login {
    my $self     = shift;
    my $data     = shift;
    my $handle   = shift;
    my $this_user;
    my $msg;

    if($data->{name}){
        $this_user = $self->{server}->get_user_from_name($data->{name});
        if($this_user){
            $this_user->{isloggedin} = 1;
            $this_user->{handle} = $handle;
            #$msg = "{clientAction:\"login\", success:1}\r\n";
            $handle->send( '{"clientAction":"login","result":1}' . $EOL );
            #$handle->send($msg);
            #$handle->send('{clientAction:"test", success:1}\r\n');

            print $handle $msg;
            if($self->{server}->{debug}){
                $self->{server}->log_this("sending:  ".$msg);
            }
            $self->{server}->log_this( $this_user->{name}." has logged back in \n");
        }else{
            my $user = TeamDX::User->new({
                'handle'     => $handle,
                'name'       => $data->{name},
                'isloggedin' => 1,
            });
            push @{$self->{server}->{users}}, $user;
            $handle->send('{clientAction:"login", success:1}\r\n');
            $self->{server}->log_this( $user->{name}." has logged in..");
        }
    }else{
        $handle->send('{clientAction:"login", success:0, error:"Can\'t log in without player name"}\r\n');
    }
}

sub logout{
    my $self   = shift;
    my $data   = shift;
    my $handle = shift;
    my $msg ="{clientAction:\"logout\", msg:\"Server has closed the connection.\"}\r\n";

    if($self->{server}->{debug}){
        $self->{server}->log_this("sending:  ".$msg);
    }
    $handle->send($msg);
    $self->{server}->remove_user($handle);
    $self->{server}->log_this($data->{name}." has logged out");
}

sub get_logged_in_users{
    my $self   = shift;
    my $data   = shift;
    my $handle = shift;
    my %response =(
        'clientAction' => 'list_logged_in_users',
        'user_list'    => undef,
    );


    foreach my $user ( @{$self->{server}->{users}} ){
        if ($user->{isloggedin}){
            push @{$response{'user_list'}}, $user->{name};
        }
    }

    my $msg = encode_json(%response);
    $handle->send($msg.$self->{server}->{eol});


}
sub get_known_users{
    my $self   = shift;
    my $data   = shift;
    my $handle = shift;

}
1;

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
    my $this_user;

    if($data->{name}){
        $this_user = $self->{server}->get_user_from_name($data->{name});
        if($this_user){
            $this_user->{isloggedin} = 1;
            $this_user->{handle} = $handle;
            $handle->send('{clientAction:"login", success:1}');
            $self->{server}->log_this( $this_user->{name}." has logged back in \n");
        }else{
            my $user = TeamDX::User->new({
                'handle'     => $handle,
                'name'       => $data->{name},
                'isloggedin' => 1,
            });
            push @{$self->{server}->{users}}, $user;
            $handle->send('{clientAction:"login", success:1}');
            $self->{server}->log_this( $user->{name}." has logged in..");
        }
    }else{
        $handle->send('{clientAction:"error", msg:"Can\'t log in without player name"}');
    }
}

sub logout{
    my $self   = shift;
    my $data   = shift;
    my $handle = shift;

    $handle->send('{clientAction:"logout", msg:"Server has closed the connection."}');
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

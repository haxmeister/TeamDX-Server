package TeamDX::Dispatcher;

use strict;
use warnings;
use HTML::TableExtract;
use LWP::Simple;

sub new {
    my ( $class, $args ) = @_;
    my $self = bless {
        'server' => $args->{'server'},
        'table reader' => HTML::TableExtract->new(depth => 0, count => 1 ),
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

sub VVC_Request{
    #sample data:
    #{"vouprID":"vvc","serverAction":"VVC_Request","url":"https://voupr.spenced.com/plugin.php?name=vvc"}
    
    my $self   = shift;
    my $data   = shift;
    my $user   = shift;
    my %response = {
        'clientAction'    => "VVC_Update",
        'vouprID'         => $data->{vouprID},
        'vouprVersion'    => "",
        'vouprLastUpdate' => '',
        'result'          => 1,
        'error'           => '',
    };
    my $content = '';
    
    # trap errors from external library;
    eval {$content = get($data->{url});};
    
    # if no content is received for whatever reason
    if (! $content){
        $response{result} = 0;
        $response{error}  = "No data was received from ".$data->{url};
        $user->send(encode_json(\%response));
        $self->{server}->log_this("No data was received from ".$data->{url};);
    }

    if ($content =~ m/<meta http-equiv=\"REFRESH\" content=\"0;url=404error.php">/){
        $response{result} = 0;
        $response{error}  = "404 error page does not exist on voupr ".$data->{url};
        $user->send(encode_json(\%response));
        $self->{server}->log_this("404 error page does not exist on voupr".$data->{url};);
    }

    $self->{'table reader'}->parse($content);

    foreach my $ts ($self->{'table reader'}->tables) {
        my $plugin_name    = $ts->rows->[0][1];
        my $plugin_version = $ts->rows->[1][1];
        my $last_release   = $ts->rows->[2][1];

        $plugin_version =~ s/\s//g ;
        $plugin_version =~ s/\(Download\)//g;
        
        $response{'vouprVersion'}    = $plugin_version;
        $response{'vouprLastUpdate'} = $last_release;
        $user->send(encode_json(\%response));
    }
}
1;

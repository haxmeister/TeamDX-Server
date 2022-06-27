package TeamDX::RPC;

use strict;
use warnings;
use JSON;
use Data::Dumper;


sub auth {
    my $caller = shift;
    my $data   = shift;
    my $sender = shift;

    $sender->{server}->DBconnect();
    my @result_list;
    my $sql = "SELECT * from users where username = ? and password = ?";
    my $sth = $sender->{db}->prepare($sql);
    $sth->execute($data->{username}, $data->{password});

    while(my $row = $sth->fetchrow_hashref()){
        push(@result_list, $row);
    }
    $sth->finish();

    # when the login successful
    if (@result_list){

        $sender->{loggedIn} = 1;
        print STDERR $data->{username}." has logged in\n";

        # respond to user client that the auth was successful
        my $msg = '{"action":"auth","result":1}';
        my $fh  = $sender->{fh};
        print $fh "$msg\r\n";

        # remove other users with the same name and update user name
        #$sender->remove_user_by_name($data->{username});
        $sender->{name} = $data->{username};



        # notify others of login
        $sender->skynet_msg_all($data->{username}." arrived..");

        # respond to user who is online
        my $users_online = join ' : ',$sender->get_online_user_names();
        $sender->skynet_msg("Users online: -- $users_online --");

        # Set permissions to match the database results (from first match)
        foreach my $key (keys %{$result_list[0]}){
            if (exists $sender->{allowed}{$key}){
                $sender->{allowed}{$key} = $result_list[0]{$key};
            }
        }
    }else{

        print STDERR "failed login attempt ".encode_json($data)."\n";
        my $msg = '{"action":"auth","result":0,"error":"user not found"}';
        my $fh  = $sender->{fh};
        print $fh ( $msg . "\r\n" );
    }
}



sub logout {
    my $caller = shift;
    my $data   = shift;
    my $sender = shift;
    print STDERR "logout: ". encode_json($data)."\n";
    $sender->logout();
}



sub announce {
    my $caller = shift;
    my $data   = shift;
    my $sender = shift;

    $data->{result} = 1;
    $sender->announce_broadcast($data);
}


sub getTimeStr {
    my $secs = shift;
    if ($secs<0) {
            return "--";
    }
    my $days = int($secs / 86400);
    my $rem = $secs - ($days*86400);
    my $hours = int($rem / 3600);
    $rem = $rem - ($hours * 3600);
    my $min = int($rem / 60);
    return sprintf("%dd %02dh %02dm", $days, $hours, $min);
}
1;

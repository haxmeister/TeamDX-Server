package TeamDX::User;

use strict;
use warnings;


sub new {
    my ( $class, $args ) = @_;

    my $self = bless {
        'handle'     => $args->{handle},
        'name'       => '',
        'isloggedin' => '',
    }, $class;
    return $self;
}




1;

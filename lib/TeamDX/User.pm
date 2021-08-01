package TeamDX::User;

use strict;
use warnings;


sub new {
    my ( $class, $args ) = @_;

    my $self = bless {
        'handle'     => $args->{handle},
        'name'       => $args->{name} || '',
        'isloggedin' => $args->{isloggedin} || '',
        'kills'      => '',
        'rank'       => '',
    }, $class;

    $self->_init();
    return $self;
}

sub _init{
    my $self = shift;
}



1;

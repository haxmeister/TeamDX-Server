package TeamDX::Game;

use strict;
use warnings;

sub new {
    my ( $class, $args ) = @_;

    my $self = bless {
        'name'      => $args->{name},
        'startTime' => "",
        'endTime'   => "",
        'team'      => {},
    }, $class;

    $self->_init();
    return $self;
}

sub _init {
    my $self = shift;
}

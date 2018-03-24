package TestStore;

use Statocles::Base 'Class';
extends 'Statocles::Store';

has objects => (
    is => 'ro',
    isa => ArrayRef,
);

sub iterator {
    my ( $self ) = @_;
    my $i = 0;
    return sub {
        my $obj = $self->objects && $self->objects->[ $i ]
                ? $self->objects->[ $i ]
                : return;
        $i++;
        $obj->{store} = $self;
        return $obj;
    };
}

1;

package Staticly::Document;
# ABSTRACT: Base class for all Staticly documents

use Staticly::Class;

has file => (
    is => 'rw',
    isa => InstanceOf['Staticly::File'],
);

has title => (
    is => 'rw',
    isa => Str,
);

has author => (
    is => 'rw',
    isa => Str,
);

has content => (
    is => 'rw',
    isa => Str,
);

sub dump {
    my ( $self ) = @_;
    return {
        map { $_ => $self->$_ } qw( title author content )
    };
}

1;

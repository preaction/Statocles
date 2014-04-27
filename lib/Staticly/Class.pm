package Staticly::Class;

use strict;
use warnings;
use base 'Staticly::Base';

sub modules {
    my ( $class, %args ) = @_;
    my @modules = $class->SUPER::modules( %args );
    return (
        @modules,
        'Moo::Lax' => [],
        'MooX::Types::MooseLike::Base' => [qw( :all )],
    );
}

1;

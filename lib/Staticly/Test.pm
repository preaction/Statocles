package Staticly::Test;

use strict;
use warnings;

use base 'Staticly::Base';

sub modules {
    my ( $class, %args ) = @_;
    my @modules = $class->SUPER::modules( %args );
    return (
        @modules,
        'Test::Most',
        'File::Temp',
        'File::Spec::Functions' => [qw( catdir catfile )],
        'Dir::Self' => [qw( __DIR__ )],
        'File::Basename' => [qw( dirname )],
        'File::Slurp' => [qw( read_file write_file )],
    );
}

1;

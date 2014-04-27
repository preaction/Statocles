package Staticly::Base;
# ABSTRACT: Base module for Staticly modules

use strict;
use warnings;
use base 'Import::Base';

sub modules {
    return (
        strict => [],
        warnings => [],
        feature => [qw( :5.10 )],
    );
}

1;


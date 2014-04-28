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
__END__

=head1 SYNOPSIS

    package MyModule;
    use Staticly::Module;

=head1 DESCRIPTION

This is the base module that all Staticly modules should use (unless they're
using a more-specific base).

This module imports the following into your namespace:

=over

=item strict

=item warnings

=item feature

Currently the 5.10 feature bundle

=back

=head1 SEE ALSO

=over

=item L<Import::Base>

=back

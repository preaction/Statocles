package Statocles::Base;
# ABSTRACT: Base module for Statocles modules

use strict;
use warnings;
use base 'Import::Base';

sub modules {
    return (
        Statocles => [],
        strict => [],
        warnings => [],
        feature => [qw( :5.10 )],
        'File::Spec::Functions' => [qw( catdir catfile splitpath splitdir catpath )],
    );
}

1;
__END__

=head1 SYNOPSIS

    package MyModule;
    use Statocles::Module;

=head1 DESCRIPTION

This is the base module that all Statocles modules should use (unless they're
using a more-specific base).

This module imports the following into your namespace:

=over

=item strict

=item warnings

=item feature

Currently the 5.10 feature bundle

=item File::Spec::Functions qw( catdir catfile splitpath splitdir catpath )

We do a lot of work with the filesystem.

=back

=head1 SEE ALSO

=over

=item L<Import::Base>

=back

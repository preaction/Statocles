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
        'Path::Tiny' => [qw( rootdir cwd )],
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

=item L<Statocles>

The base module is imported to make sure that L<File::Share> can find the right
share directory.

=item L<strict>

=item L<warnings>

=item L<feature>

Currently the 5.10 feature bundle

=item L<Path::Tiny> qw( path rootdir )

We do a lot of work with the filesystem.

=back

=head1 SEE ALSO

=over

=item L<Import::Base>

=back

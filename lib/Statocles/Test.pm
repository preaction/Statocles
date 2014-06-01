package Statocles::Test;
# ABSTRACT: Base set of imports for all Statocles tests

use strict;
use warnings;

use base 'Statocles::Base';

sub modules {
    my ( $class, %args ) = @_;
    my @modules = $class->SUPER::modules( %args );
    return (
        @modules,
        'Test::Most',
        'Dir::Self' => [qw( __DIR__ )],
        'Path::Tiny' => [qw( path tempdir )],
    );
}

1;
__END__

=head1 SYNOPSIS

    # t/mytest.t
    use Statocles::Test;

=head1 DESCRIPTION

This is the base module that all Statocles test scripts should use.

In addition to all the imports from L<Statocles::Base>, this module imports:

=over

=item Test::Most

Which includes Test::More, Test::Deep, Test::Differences, and Test::Exception.

=item Dir::Self

Provides the __DIR__ keyword.

=item Path::Tiny qw( tempdir )

To get temporary Path::Tiny objects.

=back

=head1 SEE ALSO

=over

=item L<Statocles::Base>

=back

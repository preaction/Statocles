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
        qw( Test::More Test::Deep Test::Differences Test::Exception ),
        'Dir::Self' => [qw( __DIR__ )],
        'Path::Tiny' => [qw( path tempdir )],
        'Statocles::Site',
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

=item L<Test::More>

=item L<Test::Deep>

=item L<Test::Differences>

=item L<Test::Exception>

=item L<Dir::Self>

Provides the __DIR__ keyword.

=item L<Path::Tiny> qw( path tempdir )

To create Path::Tiny objects and get temporary directories.

=back

=head1 SEE ALSO

=over

=item L<Statocles::Base>

=back

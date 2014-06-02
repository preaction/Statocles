package Statocles::Class;
# ABSTRACT: Base module for all Statocles classes

use strict;
use warnings;
use base 'Statocles::Base';

sub modules {
    my ( $class, %args ) = @_;
    my @modules = $class->SUPER::modules( %args );
    return (
        @modules,
        'Moo::Lax',
        'Types::Standard' => [qw( :all )],
        'Types::Path::Tiny' => [qw( Path )],
    );
}

1;
__END__

=head1 SYNOPSIS

    package MyClass;
    use Statocles::Class;

=head1 DESCRIPTION

This is the base module that all Statocles classes should use.

In addition to all the imports from L<Statocles::Base>, this module imports:

=over

=item L<Moo::Lax>

Moo without strictures.

=item L<Types::Standard>

To get all the Moose-y type constraints.

=item L<Types::Path::Tiny>

To get L<Type::Tiny> types for L<Path::Tiny> objects.

=back

=head1 SEE ALSO

=over

=item L<Statocles::Base>

=back

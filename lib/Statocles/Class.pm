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

=item Moo::Lax

Moo without strictures.

=item MooX::Types::MooseLike::Base

To get all the Moose-y type constraints.

=back

=head1 SEE ALSO

=over

=item L<Statocles::Base>

=back

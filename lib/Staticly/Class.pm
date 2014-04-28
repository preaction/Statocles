package Staticly::Class;
# ABSTRACT: Base module for all Staticly classes

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
__END__

=head1 SYNOPSIS

    package MyClass;
    use Staticly::Class;

=head1 DESCRIPTION

This is the base module that all Staticly classes should use.

In addition to all the imports from L<Staticly::Base>, this module imports:

=over

=item Moo::Lax

Moo without strictures.

=item MooX::Types::MooseLike::Base

To get all the Moose-y type constraints.

=back

=head1 SEE ALSO

=over

=item L<Staticly::Base>

=back

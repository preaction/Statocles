package Statocles::Role;
# ABSTRACT: Base module for all Statocles roles

use strict;
use warnings;
use base 'Statocles::Class';

sub modules {
    my ( $class, %args ) = @_;
    my @modules = grep { !/^Moo::Lax$/ } $class->SUPER::modules( %args );
    return (
        @modules,
        'Moo::Role::Lax',
    );
}

1;
__END__

=head1 SYNOPSIS

    package MyRole;
    use Statocles::Role;

=head1 DESCRIPTION

This is the base module that all Statocles roles should use.

In addition to all the imports from L<Statocles::Class> (except Moo::Lax), this
module imports:

=over

=item Moo::Role::Lax

Turns the module into a Role.

=back

=head1 SEE ALSO

=over

=item L<Statocles::Class>

=back


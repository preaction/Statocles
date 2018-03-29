package Statocles::Command;
our $VERSION = '0.092';
# ABSTRACT: The base class for command modules

=head1 SYNOPSIS

    use Statocles::Base 'Command';
    sub run {
        my ( $self, @argv ) = @_;
        ...;
    }

=head1 DESCRIPTION

This module is a base class for command modules.

=head1 SEE ALSO

=over 4

=item L<statocles>

The documentation for the command-line application.

=back

=cut

use Statocles::Base 'Class';

=attr site

The L<Statocles::Site> object for the current site.

=cut

has site => (
    is => 'ro',
    isa => InstanceOf['Statocles::Site'],
);

1;

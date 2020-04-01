package Statocles::Command;
our $VERSION = '0.098';
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
use YAML;
use Path::Tiny;

=attr site

The L<Statocles::Site> object for the current site.

=cut

has site => (
    is => 'ro',
    isa => InstanceOf['Statocles::Site'],
);

sub _get_status {
    my ( $self, $status ) = @_;
    my $path = Path::Tiny->new( '.statocles', 'status.yml' );
    return {} unless $path->exists;
    YAML::Load( $path->slurp_utf8 );
}

sub _write_status {
    my ( $self, $status ) = @_;
    Path::Tiny->new( '.statocles', 'status.yml' )->touchpath->spew_utf8( YAML::Dump( $status ) );
}

1;

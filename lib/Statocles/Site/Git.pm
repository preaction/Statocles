package Statocles::Site::Git;

use Statocles::Class;
extends 'Statocles::Site';

use File::Copy::Recursive qw( dircopy );
use Git::Repository;

=attr deploy_dir

The directory of the Git repository to deploy to.

=cut

has deploy_dir => (
    is => 'ro',
    isa => Str,
    default => '.',
);

=attr deploy_branch

The Git branch to deploy to.

=cut

has deploy_branch => (
    is => 'ro',
    isa => Str,
    default => 'master',
);

=method deploy()

Deploy the site.

=cut

sub deploy {
    my ( $self ) = @_;

    my $git = Git::Repository->new( work_tree => $self->deploy_store->path );

    my $current_branch = _current_branch( $git );

    $self->write( $self->build_store );

    if ( !_has_branch( $git, $self->deploy_branch ) ) {
        $git->run( checkout => -b => $self->deploy_branch );
    }
    else {
        $git->run( checkout => $self->deploy_branch );
    }

    dircopy( $self->build_store->path, $self->deploy_store->path );
    $git->run( add => $self->deploy_store->path );
    $git->run( commit => -m => 'Site update' );

    $git->run( checkout => $current_branch );

    return;
}

sub _current_branch {
    my ( $git ) = @_;
    my @branches = map { s/^\*\s+//; $_ } grep { /^\*/ } $git->run( 'branch' );
    return $branches[0];
}

sub _has_branch {
    my ( $git, $branch ) = @_;
    return !!grep { $_ eq $branch } map { s/^[\*\s]\s+//; $_ } $git->run( 'branch' );
}

1;
__END__

=head1 DESCRIPTION

This site deploys to a Git repository.


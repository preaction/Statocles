package Statocles::Deploy::Git;
# ABSTRACT: Deploy a site to a Git repository

use Statocles::Base 'Class';
extends 'Statocles::Deploy::File';

use Git::Repository;

=attr path

The path to the Git work tree, the root of the repository.

=attr branch

The Git branch to deploy to. Defaults to "master". If you're building a Github Pages
site for a project, you probably want to use the "gh-pages" branch.

=cut

has branch => (
    is => 'ro',
    isa => Str,
    default => sub { 'master' },
);

=attr remote

The name of the remote to deploy to. Defaults to 'origin'.

=cut

has remote => (
    is => 'ro',
    isa => Str,
    default => sub { 'origin' },
);

=method deploy( FROM_STORE, MESSAGE )

Deploy the site, copying from the given store. Returns the files deployed.

=cut

around 'deploy' => sub {
    my ( $orig, $self, $from_store, $message ) = @_;

    my $deploy_dir = $self->path;
    my $git = Git::Repository->new( work_tree => "$deploy_dir" );

    # Switch to the right branch
    my $current_branch = _current_branch( $git );
    if ( !_has_branch( $git, $self->branch ) ) {
        # Create a new, orphan branch
        _git_run( $git, checkout => '--orphan', $self->branch );
        _git_run( $git, 'rm', '-r', '-f', $deploy_dir );
    }
    else {
        _git_run( $git, checkout => $self->branch );
    }

    # Copy the files
    my @files = $self->$orig( $from_store, $message );

    # Check to see which files were changed
    my @status_lines = $git->run(
        status => '--porcelain', '--ignore-submodules', '--untracked-files',
    );
    my %in_status;
    for my $line ( @status_lines ) {
        my ( $status, $path ) = $line =~ /^\s*(\S+)\s+(.+)$/;
        $in_status{ $path } = $status;
    }

    # Commit the files
    _git_run( $git, add => grep { $in_status{ $_ } } @files );
    _git_run( $git, commit => -m => $message || "Site update" );
    if ( _has_remote( $git, $self->remote ) ) {
        _git_run( $git, push => $self->remote => $self->branch );
    }

    # Tidy up
    _git_run( $git, checkout => $current_branch );

    return @files;
};

sub _git_run {
    my ( $git, @args ) = @_;
    my $cmdline = join " ", 'git', @args;
    my $cmd = $git->command( @args );
    my $stdout = join( "\n", readline( $cmd->stdout ) ) // '';
    my $stderr = join( "\n", readline( $cmd->stderr ) ) // '';
    $cmd->close;
    my $exit = $cmd->exit;

    if ( $exit ) {
        die "git $args[0] exited with $exit\n\n-- CMD --\n$cmdline\n\n-- STDOUT --\n$stdout\n\n-- STDERR --\n$stderr\n";
    }

    return $cmd->exit;
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

sub _has_remote {
    my ( $git, $remote ) = @_;
    return !!grep { $_ eq $remote } map { s/^[\*\s]\s+//; $_ } $git->run( 'remote' );
}

1;
__END__

=head1 DESCRIPTION

This class allows a site to be deployed to a Git repository.

This class extends L<Statocles::Store::File|Statocles::Store::File>.

=head1 SEE ALSO

=over 4

=item L<Statocles::Store::File>

=item L<Statocles::Deploy>

=back


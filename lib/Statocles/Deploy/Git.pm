package Statocles::Deploy::Git;
# ABSTRACT: Deploy a site to a Git repository

use Statocles::Base 'Class';
with 'Statocles::Deploy';

use Git::Repository;

=attr path

The path to the Git work tree, the root of the repository.

=cut

has path => (
    is => 'ro',
    isa => Dir,
    coerce => Dir->coercion,
    required => 1,
);

=attr branch

The Git branch to deploy to. Defaults to "master". If you're building a Github Pages
site for a project, you probably want to use the "gh-pages" branch.

=cut

has branch => (
    is => 'ro',
    isa => Str,
    default => sub { 'master' },
);

=method deploy( FROM_STORE, MESSAGE )

Deploy the site, copying from the given store.

=cut

sub deploy {
    my ( $self, $from_store, $message ) = @_;

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
    my @files;
    my $iter = $from_store->find_files;
    while ( my $path = $iter->() ) {
        # Git versions before 1.7.4.1 require a relative path to 'git add'
        push @files, $path->relative( "/" )->stringify;

        # XXX Implement a friendlier way to copy files from Stores
        my $in_fh = $from_store->open_file( $path );
        my $out_fh = $self->path->child( $path )->openw_raw;
        while ( my $line = <$in_fh> ) {
            $out_fh->print( $line );
        }
    }

    # Commit the files
    _git_run( $git, add => @files );
    _git_run( $git, commit => -m => $message || "Site update" );
    if ( _has_remote( $git, 'origin' ) ) {
        _git_run( $git, push => origin => $self->branch );
    }

    # Tidy up
    _git_run( $git, checkout => $current_branch );

    return;
}

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


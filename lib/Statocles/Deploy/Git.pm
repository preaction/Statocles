package Statocles::Deploy::Git;
our $VERSION = '0.094';
# ABSTRACT: Deploy a site to a Git repository

=head1 DESCRIPTION

This class allows a site to be deployed to a Git repository.

This class inherits from L<Statocles::Deploy|Statocles::Deploy>.

=head1 SEE ALSO

L<Statocles::Deploy>, L<Git::Repository>

=cut

use Mojo::Base 'Statocles::Deploy';
use Git::Repository;
use Mojo::File ( );
use Statocles::Util qw( dircopy );

=attr path

The path to deploy to. Must be the root of the Git repository, or a directory
inside of the Git repository. Defaults to the application home directory.

=cut

has path => sub { shift->app->home };

=attr branch

The Git branch to deploy to. Defaults to "master". If you're building a Github Pages
site for a project, you probably want to use the "gh-pages" branch.

=cut

has branch => 'master';

=attr remote

The name of the remote to deploy to. Defaults to 'origin'.

=cut

has remote => 'origin';

=method deploy

    my @paths = $deploy->deploy( $source_path, %options );

Deploy the site, copying from the given source path.

Possible options are:

=over 4

=item clean

Remove all the current contents of the deploy directory before copying the
new content.

=item message

An optional commit message to use. Defaults to a generic message.

=back

=cut

sub deploy {
    my ( $self, $source_path, %options ) = @_;
    $source_path = Mojo::File->new( $source_path );
    my $deploy_dir = $self->path;

    # Find the repository root
    my $root = Mojo::File->new( "$deploy_dir" ); # clone
    until ( -e $root->child( '.git' ) || $root->dirname eq $root ) {
        $root = $root->dirname;
    }
    if ( !-e $root->child( '.git' ) ) {
        die qq{Deploy path "$deploy_dir" is not in a git repository\n};
    }
    my $rel_path = $deploy_dir->to_rel( $root );
    # ; say "Deploy Dir: $deploy_dir";
    # ; say "Repo root: $root";
    # ; say "Relative: $rel_path";

    my $git = Git::Repository->new( work_tree => "$root" );

    my $current_branch = _git_current_branch( $git );
    if ( !$current_branch ) {
        die qq{Repository has no branches. Please create a commit before deploying\n};
    }

    # Switch to the right branch
    if ( !_git_has_branch( $git, $self->branch ) ) {
        #; say "Creating new branch: " . $self->branch;
        # Create a new, orphan branch
        # Orphan branches were introduced in git 1.7.2
        $self->app->log->info( sprintf 'Creating deploy branch "%s"', $self->branch );
        $self->_run( $git, checkout => '--orphan', $self->branch );
        $self->_run( $git, 'rm', '-r', '-f', '.' );
    }
    else {
        #; say "Switching branches to " . $self->branch;
        $self->_run( $git, checkout => $self->branch );
    }

    if ( $options{ clean } ) {
        if ( $current_branch eq $self->branch ) {
            die "--clean on the same branch as deploy will destroy all content. Stopping.\n";
        }
        $self->app->log->info( sprintf 'Cleaning old content in branch "%s"', $self->branch );
        $self->_run( $git, 'rm', '-r', '-f', '.' );
        delete $options{ clean };
    }

    # Copy the files
    if ( $options{ clean } ) {
        $_->remove_tree for $self->path->children;
    }
    dircopy $source_path, $self->path;

    # Check to see which files were changed
    # --porcelain was added in 1.7.0
    my @status_lines = $git->run(
        status => '--porcelain', '--ignore-submodules', '--untracked-files',
    );

    my %in_status;
    for my $line ( @status_lines ) {
        my ( $status, $path ) = $line =~ /^\s*(\S+)\s+(.+)$/;
        $in_status{ $path } = $status;
    }

    #; use Data::Dumper;
    #; say Dumper \%in_status;

    # Commit the files
    my @files = map { $_->[0] }
                grep { -e $source_path->child( $_->[1] ) }
                map { [ $_, Mojo::File->new( $_ )->to_rel( $rel_path ) ] }
                keys %in_status;

    #; say "Files to commit: " . join "; ", @files;
    if ( @files ) {
        $self->app->log->info( sprintf 'Deploying %d changed files', scalar @files );
        $self->_run( $git, add => @files );
        $self->_run( $git, commit => -m => $options{message} || "Site update" );
    }
    else {
        $self->app->log->warn( 'No files changed' );
    }

    if ( _git_has_remote( $git, $self->remote ) ) {
        $self->_run( $git, push => $self->remote => $self->branch );
    }
    else {
        $self->app->log->warn(
            sprintf 'Git remote "%s" does not exist. Not pushing.', $self->remote,
        );
    }

    # Tidy up
    $self->_run( $git, checkout => $current_branch );
};

# Run the given git command on the given git repository, logging the
# command for those running in debug mode
sub _run {
    my ( $self, $git, @args ) = @_;
    $self->app->log->debug( "Running git command: " . join " ", @args );
    return _git_run( $git, @args );
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

sub _git_current_branch {
    my ( $git ) = @_;
    my @branches = map { s/^\*\s+//; $_ } grep { /^\*/ } $git->run( 'branch' );
    return $branches[0];
}

sub _git_has_branch {
    my ( $git, $branch ) = @_;
    return !!grep { $_ eq $branch } map { s/^[\*\s]\s+//; $_ } $git->run( 'branch' );
}

sub _git_has_remote {
    my ( $git, $remote ) = @_;
    return !!grep { $_ eq $remote } map { s/^[\*\s]\s+//; $_ } $git->run( 'remote' );
}

sub _git_version {
    my $output = `git --version`;
    my ( $git_version ) = $output =~ /git version (\d+[.]\d+[.]\d+)/;
    return unless $git_version;
    my $v = sprintf '%i.%03i%03i', split /[.]/, $git_version;
    return $v;
}

1;


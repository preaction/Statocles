package Statocles::Deploy::Git;
our $VERSION = '0.094';
# ABSTRACT: Deploy a site to a Git repository

use Statocles::Base 'Class';
extends 'Statocles::Deploy::File';

use Git::Repository;

=attr path

The path to deploy to. Must be the root of the Git repository, or a directory
inside of the Git repository.

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

around 'deploy' => sub {
    my ( $orig, $self, $source_path, %options ) = @_;
    $source_path = Path->coercion->( $source_path );
    my $deploy_dir = $self->path;

    # Find the repository root
    my $root = Path::Tiny->new( "$deploy_dir" ); # clone
    until ( $root->child( '.git' )->exists || $root->is_rootdir ) {
        $root = $root->parent;
    }
    if ( !$root->child( '.git' )->exists ) {
        die qq{Deploy path "$deploy_dir" is not in a git repository\n};
    }
    my $rel_path = $deploy_dir->relative( $root );
    #; say "Relative: $rel_path";

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
        $self->site->log->info( sprintf 'Creating deploy branch "%s"', $self->branch );
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
        $self->site->log->info( sprintf 'Cleaning old content in branch "%s"', $self->branch );
        $self->_run( $git, 'rm', '-r', '-f', '.' );
        delete $options{ clean };
    }

    # Copy the files
    $self->$orig( $source_path, %options );

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
                grep { $source_path->child( $_->[1] )->exists }
                map { [ $_, Path::Tiny->new( $_ )->relative( $rel_path ) ] }
                keys %in_status;

    #; say "Files to commit: " . join "; ", @files;
    if ( @files ) {
        $self->site->log->info( sprintf 'Deploying %d changed files', scalar @files );
        $self->_run( $git, add => @files );
        $self->_run( $git, commit => -m => $options{message} || "Site update" );
    }
    else {
        $self->site->log->warn( 'No files changed' );
    }

    if ( _git_has_remote( $git, $self->remote ) ) {
        $self->_run( $git, push => $self->remote => $self->branch );
    }
    else {
        $self->site->log->warn(
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
    $self->site->log->debug( "Running git command: " . join " ", @args );
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
__END__

=head1 DESCRIPTION

This class allows a site to be deployed to a Git repository.

This class consumes L<Statocles::Role::Deploy|Statocles::Role::Deploy>.

=head1 SEE ALSO

=over 4

=item L<Statocles::Role::Deploy>

=back


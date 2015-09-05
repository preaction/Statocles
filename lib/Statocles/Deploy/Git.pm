package Statocles::Deploy::Git;
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

    my @paths = $deploy->deploy( $from_store, %options );

Deploy the site, copying from the given L<from_store|Statocles::Store>.
Returns the paths that were deployed.

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
    my ( $orig, $self, $from_store, %options ) = @_;

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

    # Switch to the right branch
    my $current_branch = _current_branch( $git );
    if ( !_has_branch( $git, $self->branch ) ) {
        # Create a new, orphan branch
        # Orphan branches were introduced in git 1.7.2
        _git_run( $git, checkout => '--orphan', $self->branch );
        _git_run( $git, 'rm', '-r', '-f', '.' );
    }
    else {
        _git_run( $git, checkout => $self->branch );
    }

    if ( $options{ clean } ) {
        _git_run( $git, 'rm', '-r', '-f', '.' );
        delete $options{ clean };
    }

    # Copy the files
    my @files = $self->$orig( $from_store, %options );

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
    @files    = grep { $in_status{ $_ } }
                map { Path::Tiny->new( $rel_path, $_ ) }
                @files;

    #; say "Committing: " . Dumper \@files;
    return if !@files;

    _git_run( $git, add => @files );
    _git_run( $git, commit => -m => $options{message} || "Site update" );
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

sub _git_version {
    my $git_version = ( split ' ', `git --version` )[-1];
    return unless $git_version;
    my $v = sprintf '%i.%03i%03i', split /[.]/, $git_version;
    return $v;
}

1;
__END__

=head1 DESCRIPTION

This class allows a site to be deployed to a Git repository.

This class consumes L<Statocles::Deploy|Statocles::Deploy>.

=head1 SEE ALSO

=over 4

=item L<Statocles::Deploy>

=back


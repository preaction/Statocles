
use Statocles::Base 'Test';
BEGIN {
    my $git_version = ( split ' ', `git --version` )[-1];
    plan skip_all => 'Git not installed' unless $git_version;
    diag "Git version: $git_version";
    my $v = sprintf '%i.%03i%03i', split /[.]/, $git_version;
    plan skip_all => 'Git 1.5 or higher required' unless $v >= 1.005;
};

use Statocles::Deploy::Git;
use Statocles::App::Blog;
use File::Copy::Recursive qw( dircopy );

my $SHARE_DIR = path( __DIR__ )->parent->child( 'share' );

my @temp_args;
if ( $ENV{ NO_CLEANUP } ) {
    @temp_args = ( CLEANUP => 0 );
}

*_git_run = \&Statocles::Deploy::Git::_git_run;

subtest 'deploy' => sub {
    my $tmpdir = tempdir( @temp_args );
    diag "TMP: " . $tmpdir if @temp_args;

    my ( $deploy, $build_store, $workdir, $remotedir ) = make_deploy( $tmpdir );
    my $git = Git::Repository->new( work_tree => "$workdir" );
    my $remotegit = Git::Repository->new( work_tree => "$remotedir" );

    # Changed/added files not in the build directory do not get added
    $workdir->child( 'NEWFILE' )->spew( 'test' );

    # Origin must be on a different branch in order for push to work
    _git_run( $remotegit, branch => 'safe' );
    _git_run( $remotegit, checkout => 'safe' );

    $deploy->deploy( $build_store );

    is current_branch( $git ), 'master', 'deploy leaves us on the branch we came from';

    my $file_iter = $build_store->find_files;
    while ( my $file = $file_iter->() ) {
        ok !$workdir->child( $file->path )->exists, $file->path . ' is not in master branch';
    }

    my $master_commit_id = $git->run( 'rev-parse' => 'HEAD' );

    _git_run( $git, checkout => $deploy->branch );

    my $log = $git->run( log => -u => -n => 1 );
    like $log, qr{Site update};
    unlike $log, qr{NEWFILE};

    my $prev_log = $git->run( 'log' );
    unlike $prev_log, qr{$master_commit_id}, 'does not contain master commit';

    subtest 'files are correct' => sub {
        my $file_iter = $build_store->find_files;
        while ( my $file = $file_iter->() ) {
            ok $workdir->child( $file->path )->exists,
                'page ' . $file->path . ' is in deploy branch';
        }
    };

    _git_run( $git, checkout => 'master' );

    subtest 'deploy performs git push' => sub {
        _git_run( $remotegit, checkout => 'gh-pages' );
        my $file_iter = $build_store->find_files;
        while ( my $file = $file_iter->() ) {
            ok $remotedir->child( $file->path )->exists, $file->path . ' deployed';
        }
    };
};

done_testing;

sub make_deploy {
    my ( $tmpdir ) = @_;

    my $workdir = $tmpdir->child( 'workdir' );
    $workdir->mkpath;
    my $remotedir = $tmpdir->child( 'remotedir' );
    $remotedir->mkpath;

    # Git before 1.6.4 does not allow directory as argument to "init"
    my $cwd = cwd;
    chdir $workdir;
    Git::Repository->run( "init" );
    chdir $cwd;

    chdir $remotedir;
    Git::Repository->run( "init" );
    chdir $cwd;

    my $remotegit = Git::Repository->new( work_tree => "$remotedir" );
    my $workgit = Git::Repository->new( work_tree => "$workdir" );
    _git_run( $workgit, remote => add => origin => "$remotedir" );

    # Set some config so Git knows who we are (and doesn't complain)
    for my $git ( $workgit, $remotegit ) {
        _git_run( $git, config => 'user.name' => 'Statocles Test User' );
        _git_run( $git, config => 'user.email' => 'statocles@example.com' );
    }

    # Copy the store into the repository, so we have something to commit
    dircopy( $SHARE_DIR->child( qw( app blog ) )->stringify, $remotedir->child( 'blog' )->stringify )
        or die "Could not copy directory: $!";
    _git_run( $remotegit, add => 'blog' );
    _git_run( $remotegit, commit => -m => 'Initial commit' );
    _git_run( $workgit, pull => origin => 'master' );

    my $build_store = Statocles::Store::File->new(
        path => $SHARE_DIR->child( qw( deploy ) ),
    );

    my $deploy = Statocles::Deploy::Git->new(
        path => $workdir,
        branch => 'gh-pages',
    );

    return ( $deploy, $build_store, $workdir, $remotedir );
}

sub current_branch {
    my ( $git ) = @_;
    my @branches = map { s/^\*\s+//; $_ } grep { /^\*/ } $git->run( 'branch' );
    return $branches[0];
}


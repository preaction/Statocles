
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

subtest 'constructor' => sub {
    test_constructor(
        'Statocles::Deploy::Git',
        default => {
            path => Path::Tiny->new( '.' ),
        },
    );
};

subtest 'deploy' => sub {
    my $tmpdir = tempdir( @temp_args );
    diag "TMP: " . $tmpdir if @temp_args;

    my ( $deploy, $build_store, $workdir, $remotedir ) = make_deploy( $tmpdir );
    my $git = Git::Repository->new( work_tree => "$workdir" );
    my $remotegit = Git::Repository->new( work_tree => "$remotedir" );

    # Changed/added files not in the build directory do not get added
    $workdir->child( 'NEWFILE' )->spew( 'test' );

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

subtest 'deploy to specific remote' => sub {
    my $tmpdir = tempdir( @temp_args );
    diag "TMP: " . $tmpdir if @temp_args;

    my ( $deploy, $build_store, $workdir, $remotedir )
        = make_deploy( $tmpdir, branch => 'master', remote => 'deploy' );

    my $remotework = $tmpdir->child( 'remote_work' );
    $remotework->mkpath;

    my $git = Git::Repository->new( work_tree => "$workdir" );
    my $remotegit = Git::Repository->new( git_dir => "$remotedir", work_tree => "$remotework" );

    $deploy->deploy( $build_store );

    my $master_commit_id = $git->run( 'rev-parse' => 'HEAD' );

    _git_run( $remotegit, checkout => '-f' );
    my $file_iter = $build_store->find_files;
    while ( my $file = $file_iter->() ) {
        ok $remotework->child( $file->path )->exists, $file->path . ' deployed';
    }
};

subtest 'deploy with submodules and ignored files' => sub {
    my $tmpdir = tempdir( @temp_args );
    diag "TMP: " . $tmpdir if @temp_args;

    my ( $deploy, $build_store, $workdir, $remotedir )
        = make_deploy( $tmpdir, branch => 'master' );

    my $git = Git::Repository->new( work_tree => "$workdir" );

    # Add a submodule to the repo
    # Git before 1.6.4 does not allow directory as argument to "init"
    my $cwd = cwd;
    my $submoduledir = $tmpdir->child('submodule');
    $submoduledir->mkpath;
    chdir $submoduledir;
    Git::Repository->run( "init" );
    chdir $cwd;
    my $submodule = Git::Repository->new( work_tree => $submoduledir->stringify );
    # Add something to pull from the submodule
    $submoduledir->child( 'README' )->spew( 'Do not commit!' );
    $submodule->run( add => 'README' );
    $submodule->run( commit => '-m' => 'add README' );

    _git_run( $git, submodule => add => "$submoduledir" );
    _git_run( $git, commit => '-m' => 'add submodule' );

    # Add a gitignore to the repo
    $workdir->child( '.gitignore' )->spew( ".DS_Store\n*.swp\n" );
    $workdir->child( '.DS_Store' )->spew( 'Do not commit!' );
    $workdir->child( 'test.swp' )->spew( 'Do not commit!' );
    _git_run( $git, add => '.gitignore' );
    _git_run( $git, commit => '-m' => 'add gitignore' );
    _git_run( $git, push => origin => 'master' );

    # Add the same files to the build store, so that when they're deployed,
    # they would cause an error if added to the repository
    my $build_dir = $tmpdir->child( 'build' );
    $build_dir->mkpath;
    dircopy( $SHARE_DIR->child( qw( deploy ) )->stringify, $build_dir->stringify )
        or die "Could not copy directory: $!";
    $build_store = Statocles::Store::File->new( path => $build_dir );
    $build_dir->child( 'test.swp' )->spew( 'ERROR!' );
    $build_dir->child( '.DS_Store' )->spew( 'ERROR!' );
    $build_dir->child( 'submodule' => 'README' )->touchpath->spew( 'ERROR!' );

    lives_ok {
        $deploy->deploy( $build_store );
    } 'deploy succeeds';

    my $master_commit_id = $git->run( 'rev-parse' => 'HEAD' );

    my $remotework = $tmpdir->child( 'remote_work' );
    $remotework->mkpath;
    my $remotegit = Git::Repository->new( git_dir => "$remotedir", work_tree => "$remotework" );

    _git_run( $remotegit, checkout => '-f' );
    my $file_iter = $build_store->find_files;
    while ( my $file = $file_iter->() ) {
        # Ignored files do not get deployed
        if ( $file eq '/.DS_Store' || $file eq '/test.swp' ) {
            ok !$remotework->child( $file->path )->exists, $file->path . ' not deployed';
        }
        elsif ( $file =~ m{/submodule} ) {
            ok !$remotework->child( $file->path )->exists, $file->path . ' not deployed';
        }
        else {
            ok $remotework->child( $file->path )->exists, $file->path . ' deployed';
        }
    }
};



done_testing;

sub make_deploy {
    my ( $tmpdir, %args ) = @_;

    $args{ remote } ||= "origin";
    $args{ branch } ||= "gh-pages";

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
    Git::Repository->run( "init", '--bare' );
    chdir $cwd;

    my $remotegit = Git::Repository->new( work_tree => "$remotedir" );
    my $workgit = Git::Repository->new( work_tree => "$workdir" );
    _git_run( $workgit, remote => add => $args{remote} => "$remotedir" );

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
    _git_run( $workgit, pull => $args{remote} => 'master' );

    my $build_store = Statocles::Store::File->new(
        path => $SHARE_DIR->child( qw( deploy ) ),
    );

    my $deploy = Statocles::Deploy::Git->new(
        path => $workdir,
        branch => $args{branch},
        remote => $args{remote},
    );

    return ( $deploy, $build_store, $workdir, $remotedir );
}

sub current_branch {
    my ( $git ) = @_;
    my @branches = map { s/^\*\s+//; $_ } grep { /^\*/ } $git->run( 'branch' );
    return $branches[0];
}


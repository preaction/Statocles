use Test::Lib;
use My::Test;
use Statocles::Deploy::Git;
BEGIN {
    my $git_version = Statocles::Deploy::Git->_git_version;
    plan skip_all => 'Git not installed' unless $git_version;
    diag "Git version: $git_version";
    plan skip_all => 'Git 1.7.2 or higher required' unless $git_version >= 1.007002;
};

use Statocles::App::Blog;
use Statocles::Util qw( dircopy );

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
    my ( $commit_id ) = $log =~ /commit (\S+)/;
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
        ok !$remotedir->child( 'README' )->exists, 'gh-pages branch is orphan and clean';
    };

    subtest 'nothing to deploy bails out without commit' => sub {
        $deploy->deploy( $build_store );
        is current_branch( $git ), 'master', 'deploy leaves us on the branch we came from';
        _git_run( $git, checkout => $deploy->branch );
        my $log = $git->run( log => -u => -n => 1 );
        like $log, qr/commit $commit_id/, 'no new commit created';
        like $deploy->site->log->history->[-1][2], qr{\QNo files changed. Stopping.},
            'we warned the user that we did nothing';
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

    _git_run( $remotegit, checkout => '-f', 'master' );
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
    my $cwd = cwd;
    my $submoduledir = $tmpdir->child('submodule');
    $submoduledir->mkpath;
    my $submodule = make_git( $submoduledir );
    # Add something to pull from the submodule
    $submoduledir->child( 'README' )->spew( 'Do not commit!' );
    $submodule->run( add => 'README' );
    $submodule->run( commit => '-m' => 'add README' );

    # Git::Repository sets the "GIT_WORK_TREE" envvar, which makes most
    # submodule commands fail, so we have to unset it.
    _git_run( $git, submodule => add => "file://$submoduledir",
        { env => { GIT_WORK_TREE => undef } }
    );
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
    dircopy( $SHARE_DIR->child( qw( deploy ) ), $build_dir );
    $build_store = Statocles::Store->new( path => $build_dir );
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

subtest 'deploy to subdirectory in git repo' => sub {
    my $tmpdir = tempdir( @temp_args );
    diag "TMP: " . $tmpdir if @temp_args;

    my ( undef, $build_store, $workdir, $remotedir )
        = make_deploy( $tmpdir, branch => 'master', remote => 'origin' );

    $workdir->child( 'subdir' )->mkpath;

    my $deploy = Statocles::Deploy::Git->new(
        site => build_test_site,
        path => $workdir->child( 'subdir' ),
    );

    my $remotework = $tmpdir->child( 'remote_work' );
    $remotework->mkpath;

    my $git = Git::Repository->new( work_tree => "$workdir" );
    my $remotegit = Git::Repository->new( git_dir => "$remotedir", work_tree => "$remotework" );

    $deploy->deploy( $build_store );

    my $master_commit_id = $git->run( 'rev-parse' => 'HEAD' );

    _git_run( $remotegit, checkout => '-f', 'master' );
    my $file_iter = $build_store->find_files;
    while ( my $file = $file_iter->() ) {
        ok $remotework->child( 'subdir' )->child( $file->path )->exists, 'subdir ' . $file->path . ' deployed';
    }

};

subtest '--clean' => sub {
    my $tmpdir = tempdir( @temp_args );
    diag "TMP: " . $tmpdir if @temp_args;

    my ( $deploy, $build_store, $workdir, $remotedir ) = make_deploy( $tmpdir );
    my $remotework = $tmpdir->child( 'remote_work' );
    $remotework->mkpath;
    my $remotegit = Git::Repository->new( git_dir => "$remotedir", work_tree => "$remotework" );

    # Add some files that should be cleaned up
    $workdir->child( 'needs-cleaning.txt' )->spew_utf8( 'Ha ha!' );
    my $workgit = Git::Repository->new( work_tree => "$workdir" );
    # Create the branch first
    _git_run( $workgit, checkout => '--orphan', 'gh-pages' );
    _git_run( $workgit, 'rm', '-r', '-f', '.' );
    _git_run( $workgit, add => 'needs-cleaning.txt' );
    _git_run( $workgit, commit => '-m' => 'add new file outside of site' );
    _git_run( $workgit, push => origin => 'gh-pages' );
    _git_run( $workgit, checkout => 'master' );

    subtest 'deploy without clean does not remove files' => sub {
        $deploy->deploy( $build_store );
        _git_run( $workgit, checkout => 'gh-pages' );
        ok $workdir->child( 'needs-cleaning.txt' )->is_file, 'default deploy did not remove file';
        _git_run( $workgit, checkout => 'master' );
        _git_run( $remotegit, checkout => '-f', 'gh-pages' );
        ok $remotework->child( 'needs-cleaning.txt' )->is_file, 'pushed to remote';
    };

    subtest 'deploy with clean removes files first' => sub {
        $deploy->deploy( $build_store, clean => 1 );
        _git_run( $workgit, checkout => 'gh-pages' );
        ok !$workdir->child( 'needs-cleaning.txt' )->is_file, 'default deploy remove files';
        _git_run( $workgit, checkout => 'master' );
        _git_run( $remotegit, checkout => '-f', 'gh-pages' );
        ok !$remotework->child( 'needs-cleaning.txt' )->is_file, 'pushed to remote';
    };
};

subtest '--message' => sub {
    my $tmpdir = tempdir( @temp_args );
    diag "TMP: " . $tmpdir if @temp_args;

    my ( $deploy, $build_store, $workdir, $remotedir ) = make_deploy( $tmpdir );
    my $remotegit = Git::Repository->new( git_dir => "$remotedir" );
    my $workgit = Git::Repository->new( work_tree => "$workdir" );

    $deploy->deploy( $build_store, message => 'My commit message' );

    my $worklog = $workgit->run( log => 'gh-pages' );
    like $worklog, qr{My commit message}, 'commit message committed';

    my $remotelog = $remotegit->run( log => 'gh-pages' );
    like $remotelog, qr{My commit message}, 'commit message pushed';
};

subtest 'errors' => sub {
    subtest 'not in a git repo' => sub {
        my $tmpdir = tempdir;

        my ( undef, $build_store, undef, undef )
            = make_deploy( $tmpdir );

        my $not_git_path = tempdir;
        my $deploy = Statocles::Deploy::Git->new(
            site => build_test_site,
            path => $not_git_path,
        );

        throws_ok { $deploy->deploy( $build_store ) }
            qr{Deploy path "$not_git_path" is not in a git repository\n};

    };

    subtest 'deploy from branch not yet born' => sub {
        my $tmpdir = tempdir( @temp_args );
        diag "TMP: " . $tmpdir if @temp_args;
        my $work_git = make_git( $tmpdir );

        my $build_store = Statocles::Store->new(
            path => $SHARE_DIR->child( qw( deploy ) ),
        );

        my $deploy = Statocles::Deploy::Git->new(
            site => build_test_site,
            path => $tmpdir,
            branch => 'gh-pages',
        );

        throws_ok { $deploy->deploy( $build_store ) }
            qr{Repository has no branches\. Please create a commit before deploying\n};
    };

};

done_testing;

sub make_git {
    my ( $dir, %args ) = @_;

    Git::Repository->run( "init", ( $args{bare} ? ( '--bare' ) : () ), "$dir" );

    my $git = Git::Repository->new( work_tree => "$dir" );

    # Set some config so Git knows who we are (and doesn't complain)
    _git_run( $git, config => 'user.name' => 'Statocles Test User' );
    _git_run( $git, config => 'user.email' => 'statocles@example.com' );

    return $git;
}

sub make_deploy {
    my ( $tmpdir, %args ) = @_;

    $args{ remote } ||= "origin";
    $args{ branch } ||= "gh-pages";

    my $workdir = $tmpdir->child( 'workdir' );
    $workdir->mkpath;
    my $remotedir = $tmpdir->child( 'remotedir' );
    $remotedir->mkpath;

    my $remotegit = make_git( $remotedir, bare => 1 );
    my $workgit = make_git( $workdir );
    _git_run( $workgit, remote => add => $args{remote} => "$remotedir" );

    # Copy the store into the repository, so we have something to commit
    dircopy( $SHARE_DIR->child( qw( app blog ) ), $remotedir->child( 'blog' ) );
    _git_run( $remotegit, add => 'blog' );

    # Also add a file not in the store, to test that we create an orphan branch
    $remotedir->child( "README" )->spew( "Repository readme, not in deploy branch" );
    _git_run( $remotegit, add => 'README' );

    _git_run( $remotegit, commit => -m => 'Initial commit' );
    _git_run( $workgit, pull => $args{remote} => 'master' );

    my $build_store = Statocles::Store->new(
        path => $SHARE_DIR->child( qw( deploy ) ),
    );

    my $deploy = Statocles::Deploy::Git->new(
        path => $workdir,
        site => build_test_site,
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


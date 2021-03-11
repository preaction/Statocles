use Test::Lib;
use My::Test;
use Statocles::Deploy::Git;
use TestDeploy;
use Statocles::Site;
BEGIN {
    my $git_version = Statocles::Deploy::Git->_git_version;
    plan skip_all => 'Git not installed' unless $git_version;
    diag "Git version: $git_version";
    plan skip_all => 'Git 1.7.2 or higher required' unless $git_version >= 1.007002;
};

use Statocles::Util qw( dircopy );

my $SHARE_DIR = path( __DIR__ )->parent->child( 'share' );

my @temp_args;
if ( $ENV{ NO_CLEANUP } ) {
    @temp_args = ( CLEANUP => 0 );
}

*_git_run = \&Statocles::Deploy::Git::_git_run;

my $site = Statocles::Site->new(
    deploy => TestDeploy->new,
);

subtest 'constructor' => sub {
    test_constructor(
        'Statocles::Deploy::Git',
        default => {
            path => Path::Tiny->new( '.' ),
        },
    );
};

my @pages = qw( index.html doc.markdown foo/index.html );

subtest 'deploy' => sub {
    my $tmpdir = tempdir( @temp_args );
    diag "TMP: " . $tmpdir if @temp_args;

    my ( $deploy, $workdir, $remotedir ) = make_deploy( $tmpdir );
    my $git = Git::Repository->new( work_tree => "$workdir" );
    my $remotegit = Git::Repository->new( work_tree => "$remotedir" );

    # Changed/added files not in the build directory do not get added
    $workdir->child( 'NEWFILE' )->spew( 'test' );

    $deploy->deploy( $SHARE_DIR->child( 'deploy' ) );

    is current_branch( $git ), 'master', 'deploy leaves us on the branch we came from';

    for my $page ( @pages ) {
        ok !$workdir->child( $page )->exists, $page . ' is not in master branch';
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
        for my $page ( @pages ) {
            ok $workdir->child( $page )->exists,
                'page ' . $page . ' is in deploy branch';
        }
    };

    _git_run( $git, checkout => 'master' );

    subtest 'deploy performs git push' => sub {
        _git_run( $remotegit, checkout => 'gh-pages' );
        for my $page ( @pages ) {
            ok $remotedir->child( $page )->exists, $page . ' deployed';
        }
        ok !$remotedir->child( 'README' )->exists, 'gh-pages branch is orphan and clean';
        _git_run( $remotegit, checkout => 'master' );
    };

    subtest 'nothing to deploy bails out without commit' => sub {
        $deploy->deploy( $SHARE_DIR->child( 'deploy' ) );
        is current_branch( $git ), 'master', 'deploy leaves us on the branch we came from';
        _git_run( $git, checkout => $deploy->branch );
        my $log = $git->run( log => -u => -n => 1 );
        like $log, qr/commit $commit_id/, 'no new commit created';
        like $deploy->site->log->history->[-1][2], qr{\QNo files changed},
            'we warned the user that we updated nothing';
    };

    subtest 'nothing to deploy still pushes' => sub {
        _git_run( $git, checkout => $deploy->branch );
        $workdir->child( 'TEST_PUSH' )->spew( 'Push!' );
        _git_run( $git, add => 'TEST_PUSH' );
        _git_run( $git, commit => '-m' => 'Add test' );

        my $log = $git->run( log => -u => -n => 1 );
        my ( $commit_id ) = $log =~ /commit (\S+)/;

        _git_run( $git, checkout => 'master' );
        $deploy->deploy( $SHARE_DIR->child( 'deploy' ) );
        is current_branch( $git ), 'master', 'deploy leaves us on the branch we came from';
        _git_run( $git, checkout => $deploy->branch );
        $log = $git->run( log => -u => -n => 1 );
        like $log, qr/commit $commit_id/, 'no new commit created';
        like $deploy->site->log->history->[-1][2], qr{\QNo files changed},
            'we warned the user that we updated nothing';

        _git_run( $remotegit, checkout => 'gh-pages' );
        $log = $git->run( log => -u => -n => 1 );
        my ( $remote_commit_id ) = $log =~ /commit (\S+)/;
        ok $remotedir->child( 'TEST_PUSH' )->exists, 'gh-pages branch was pushed';
        is $remote_commit_id, $commit_id, 'local commit exists on remote branch';
        _git_run( $remotegit, checkout => 'master' );
    };
};

subtest 'deploy to specific remote' => sub {
    my $tmpdir = tempdir( @temp_args );
    diag "TMP: " . $tmpdir if @temp_args;

    my ( $deploy, $workdir, $remotedir )
        = make_deploy( $tmpdir, branch => 'master', remote => 'deploy' );

    my $remotework = $tmpdir->child( 'remote_work' );
    $remotework->mkpath;

    my $git = Git::Repository->new( work_tree => "$workdir" );
    my $remotegit = Git::Repository->new( git_dir => "$remotedir", work_tree => "$remotework" );

    $deploy->deploy( $SHARE_DIR->child( 'deploy' ) );

    my $master_commit_id = $git->run( 'rev-parse' => 'HEAD' );

    _git_run( $remotegit, checkout => '-f', 'master' );
    for my $page ( @pages ) {
        ok $remotework->child( $page )->exists, $page . ' deployed';
    }
};

subtest 'deploy with submodules and ignored files' => sub {
    my $tmpdir = tempdir( @temp_args );
    diag "TMP: " . $tmpdir if @temp_args;

    my ( $deploy, $workdir, $remotedir )
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
    $build_dir->child( 'test.swp' )->spew( 'ERROR!' );
    $build_dir->child( '.DS_Store' )->spew( 'ERROR!' );
    $build_dir->child( 'submodule' => 'README' )->touchpath->spew( 'ERROR!' );
    my @build_pages = (
        @pages, 'test.swp', '.DS_Store', 'submodule/path.html',
    );

    lives_ok { $deploy->deploy( $build_dir ) } 'deploy succeeds';

    my $master_commit_id = $git->run( 'rev-parse' => 'HEAD' );

    my $remotework = $tmpdir->child( 'remote_work' );
    $remotework->mkpath;
    my $remotegit = Git::Repository->new( git_dir => "$remotedir", work_tree => "$remotework" );

    _git_run( $remotegit, checkout => '-f' );
    for my $page ( @build_pages ) {
        # Ignored files do not get deployed
        if ( $page eq '.DS_Store' || $page eq 'test.swp' ) {
            ok !$remotework->child( $page )->exists, $page . ' not deployed';
        }
        elsif ( $page =~ m{^submodule} ) {
            ok !$remotework->child( $page )->exists, $page . ' not deployed';
        }
        else {
            ok $remotework->child( $page )->exists, $page . ' deployed';
        }
    }
};

subtest 'deploy to subdirectory in git repo' => sub {
    my $tmpdir = tempdir( @temp_args );
    diag "TMP: " . $tmpdir if @temp_args;

    my ( undef, $workdir, $remotedir )
        = make_deploy( $tmpdir, branch => 'master', remote => 'origin' );

    $workdir->child( 'subdir' )->mkpath;

    my $deploy = Statocles::Deploy::Git->new(
        site => $site,
        path => $workdir->child( 'subdir' ),
    );

    my $remotework = $tmpdir->child( 'remote_work' );
    $remotework->mkpath;

    my $git = Git::Repository->new( work_tree => "$workdir" );
    my $remotegit = Git::Repository->new( git_dir => "$remotedir", work_tree => "$remotework" );

    $deploy->deploy( $SHARE_DIR->child( 'deploy' ) );

    my $master_commit_id = $git->run( 'rev-parse' => 'HEAD' );

    _git_run( $remotegit, checkout => '-f', 'master' );
    for my $page ( @pages ) {
        ok $remotework->child( 'subdir' )->child( $page )->exists,
            'subdir ' . $page . ' deployed';
    }

};

subtest '--clean' => sub {
    my $tmpdir = tempdir( @temp_args );
    diag "TMP: " . $tmpdir if @temp_args;

    my ( $deploy, $workdir, $remotedir ) = make_deploy( $tmpdir );
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
        $deploy->deploy( $SHARE_DIR->child( 'deploy' ) );
        _git_run( $workgit, checkout => 'gh-pages' );
        ok $workdir->child( 'needs-cleaning.txt' )->is_file, 'default deploy did not remove file';
        _git_run( $workgit, checkout => 'master' );
        _git_run( $remotegit, checkout => '-f', 'gh-pages' );
        ok $remotework->child( 'needs-cleaning.txt' )->is_file, 'pushed to remote';
    };

    subtest 'deploy with clean removes files first' => sub {
        $deploy->deploy( $SHARE_DIR->child( 'deploy' ), clean => 1 );
        _git_run( $workgit, checkout => 'gh-pages' );
        ok !$workdir->child( 'needs-cleaning.txt' )->is_file, 'default deploy remove files';
        _git_run( $workgit, checkout => 'master' );
        _git_run( $remotegit, checkout => '-f', 'gh-pages' );
        ok !$remotework->child( 'needs-cleaning.txt' )->is_file, 'pushed to remote';
    };

    subtest 'clean dies when content/deploy are sharing the same branch' => sub {
        my $tmpdir = tempdir( @temp_args );
        my ( $deploy, $workdir, $remotedir )
            = make_deploy( $tmpdir, branch => 'master' );
        $workdir->child( qw( static.txt ) )->spew_utf8( 'Foo' );
        throws_ok {
            $deploy->deploy( $SHARE_DIR->child( 'deploy' ), clean => 1 );
        } qr{\Q--clean on the same branch as deploy will destroy all content. Stopping.};
        ok $workdir->child( qw( static.txt ) )->is_file,
            'content file /static.txt is not destroyed';
    };

};

subtest 'deploy configured with missing remote' => sub {

    subtest 'default remote "origin" does not exist' => sub {
        my $tmpdir = tempdir( @temp_args );
        diag "TMP: " . $tmpdir if @temp_args;

        my ( $deploy, $workdir, $remotedir ) = make_deploy( $tmpdir );
        my $workgit = Git::Repository->new( work_tree => "$workdir" );
        $workgit->run( qw( remote rm origin ) );

        $deploy->deploy( $SHARE_DIR->child( 'deploy' ) );
        my $log = $deploy->site->log->history;
        ok scalar( grep { $_->[2] =~ qr{\QGit remote "origin" does not exist. Not pushing.} } @$log ),
            'warn user that we did not push'
                or diag explain $log;
    };

    subtest 'configured remote does not exist' => sub {
        my $tmpdir = tempdir( @temp_args );
        diag "TMP: " . $tmpdir if @temp_args;

        my ( $deploy, $workdir, $remotedir )
            = make_deploy( $tmpdir, remote => 'nondefault' );
        my $workgit = Git::Repository->new( work_tree => "$workdir" );
        $workgit->run( qw( remote rm nondefault ) );

        $deploy->deploy( $SHARE_DIR->child( 'deploy' ) );
        my $log = $deploy->site->log->history;
        ok scalar( grep { $_->[2] =~ qr{\QGit remote "nondefault" does not exist. Not pushing.} } @$log ),
            'warn user that we did not push'
                or diag explain $log;
    };

};

subtest '--message' => sub {
    my $tmpdir = tempdir( @temp_args );
    diag "TMP: " . $tmpdir if @temp_args;

    my ( $deploy, $workdir, $remotedir ) = make_deploy( $tmpdir );
    my $remotegit = Git::Repository->new( git_dir => "$remotedir" );
    my $workgit = Git::Repository->new( work_tree => "$workdir" );

    $deploy->deploy( $SHARE_DIR->child( 'deploy' ), message => 'My commit message' );

    my $worklog = $workgit->run( log => 'gh-pages' );
    like $worklog, qr{My commit message}, 'commit message committed';

    my $remotelog = $remotegit->run( log => 'gh-pages' );
    like $remotelog, qr{My commit message}, 'commit message pushed';
};

subtest 'errors' => sub {
    subtest 'not in a git repo' => sub {
        my $tmpdir = tempdir;

        my ( undef, undef, undef )
            = make_deploy( $tmpdir );

        my $not_git_path = tempdir;
        my $deploy = Statocles::Deploy::Git->new(
            site => $site,
            path => $not_git_path,
        );

        throws_ok { $deploy->deploy( $SHARE_DIR->child( 'deploy' ) ) }
            qr{Deploy path "$not_git_path" is not in a git repository\n};

    };

    subtest 'deploy from branch not yet born' => sub {
        my $tmpdir = tempdir( @temp_args );
        diag "TMP: " . $tmpdir if @temp_args;
        my $work_git = make_git( $tmpdir );

        my $deploy = Statocles::Deploy::Git->new(
            site => $site,
            path => $tmpdir,
            branch => 'gh-pages',
        );

        throws_ok { $deploy->deploy( $SHARE_DIR->child( 'deploy' ) ) }
            qr{Repository has no branches\. Please create a commit before deploying\n};
    };

};

done_testing;

sub make_git {
    my ( $dir, %args ) = @_;

    Git::Repository->run( "init", ( $args{bare} ? ( '--bare' ) : () ), '-b', 'master', "$dir" );

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

    # Also add a file not in the store, to test that we create an orphan branch
    $remotedir->child( "README" )->spew( "Repository readme, not in deploy branch" );
    _git_run( $remotegit, add => 'README' );

    _git_run( $remotegit, commit => -m => 'Initial commit' );
    _git_run( $workgit, pull => $args{remote} => 'master' );

    my $deploy = Statocles::Deploy::Git->new(
        path => $workdir,
        site => $site,
        branch => $args{branch},
        remote => $args{remote},
    );

    return ( $deploy, $workdir, $remotedir );
}

sub current_branch {
    my ( $git ) = @_;
    my @branches = map { s/^\*\s+//; $_ } grep { /^\*/ } $git->run( 'branch' );
    return $branches[0];
}


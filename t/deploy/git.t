
=head1 DESCRIPTION

This tests the Git deploy class

=head1 SEE ALSO

L<Git::Repository>

=cut

use Mojo::Base -strict;
use Test::More;
use Test::Mojo;
use FindBin qw( $Bin );
use Mojo::File qw( path tempdir );

use Statocles::Deploy::Git;
BEGIN {
    my $git_version = Statocles::Deploy::Git->_git_version;
    plan skip_all => 'Git not installed' unless $git_version;
    diag "Git version: $git_version";
    plan skip_all => 'Git 1.7.2 or higher required' unless $git_version >= 1.007002;
};

use Statocles::Util qw( dircopy );

*_git_run = \&Statocles::Deploy::Git::_git_run;

local $ENV{MOJO_HOME} = path( $Bin, '..', 'share', 'deploy' );
my @pages = qw(
    advent/index.rss advent/index.html index.html
    blog/first-post/index.html blog/second-post/index.html
    avatar.jpg about/index.html
);

if ( $ENV{REBUILD_DEPLOY} ) {
    my $app = Statocles->new;
    local $ENV{MOJO_HOME} = path( $Bin, '..', 'share', 'app' );
    $app->export->export({
        to => path( $Bin, '..', 'share', 'deploy' ),
        pages => [ @pages, qw( about ) ],
    });
}

my $t = Test::Mojo->new( 'Statocles' );
if ( !$ENV{HARNESS_IS_VERBOSE} ) {
    my $log_str;
    open my $log_fh, '>', \$log_str;
    $t->app->log->level( 'warn' );
    $t->app->log->handle( $log_fh );
}
$t->app->log->max_history_size( 5000 );

subtest 'deploy' => sub {
    my ( $tempdir, $workdir, $remotedir ) = make_deploy();
    my $git = Git::Repository->new( work_tree => "$workdir" );
    my $remotegit = Git::Repository->new( work_tree => "$remotedir" );

    # Changed/added files not in the build directory do not get added
    $workdir->child( 'NEWFILE' )->spurt( 'test' );

    my $deploy = Statocles::Deploy::Git->new(
        app => $t->app,
        path => $workdir,
        branch => 'gh-pages',
    );
    $deploy->deploy( $ENV{MOJO_HOME} );

    is current_branch( $git ), 'master', 'deploy leaves us on the branch we came from';

    for my $page ( @pages ) {
        ok !-e $workdir->child( $page ), $page . ' is not in master branch';
    }

    my $master_commit_id = $git->run( 'rev-parse' => 'HEAD' );

    _git_run( $git, checkout => $deploy->branch );

    my $log = $git->run( log => -u => -n => 1 );
    my ( $commit_id ) = $log =~ /commit (\S+)/;
    like $log, qr{Site update}, 'log message is correct';
    unlike $log, qr{NEWFILE}, 'file not in the build directory is not added';

    my $prev_log = $git->run( 'log' );
    unlike $prev_log, qr{$master_commit_id}, 'does not contain master commit';

    subtest 'files are correct' => sub {
        for my $page ( @pages ) {
            ok -e $workdir->child( $page ),
                'page ' . $page . ' is in deploy branch'
                    or diag explain [ $workdir->list ];
        }
    };

    _git_run( $git, checkout => 'master' );

    subtest 'deploy performs git push' => sub {
        _git_run( $remotegit, checkout => 'gh-pages' );
        for my $page ( @pages ) {
            ok -e $remotedir->child( $page ), $page . ' deployed';
        }
        ok !-e $remotedir->child( 'README' ), 'gh-pages branch is orphan and clean';
        _git_run( $remotegit, checkout => 'master' );
    };

    subtest 'nothing to deploy bails out without commit' => sub {
        # Just immediately repeat the deploy to make sure nothing
        # happens again
        $deploy->deploy( $ENV{MOJO_HOME} );
        is current_branch( $git ), 'master', 'deploy leaves us on the branch we came from';
        _git_run( $git, checkout => $deploy->branch );
        my $log = $git->run( log => -u => -n => 1 );
        like $log, qr/commit $commit_id/, 'no new commit created';
        ok +( grep { $_->[2] =~ /\QNo files changed/ } @{ $deploy->app->log->history } ),
            'we warned the user that we updated nothing';
    };

    subtest 'nothing to deploy still pushes' => sub {
        # Add a commit on our deploy branch but do not push it. If the
        # push fails during the deploy, running deploy again should
        # still push it.
        _git_run( $git, checkout => $deploy->branch );
        $workdir->child( 'TEST_PUSH' )->spurt( 'Push!' );
        _git_run( $git, add => 'TEST_PUSH' );
        _git_run( $git, commit => '-m' => 'Add test' );

        my $log = $git->run( log => -u => -n => 1 );
        my ( $commit_id ) = $log =~ /commit (\S+)/;

        _git_run( $git, checkout => 'master' );
        $deploy->deploy( $ENV{MOJO_HOME} );
        is current_branch( $git ), 'master', 'deploy leaves us on the branch we came from';
        _git_run( $git, checkout => $deploy->branch );
        $log = $git->run( log => -u => -n => 1 );
        like $log, qr/commit $commit_id/, 'no new commit created';
        ok +( grep { $_->[2] =~ /\QNo files changed/ } @{ $deploy->app->log->history } ),
            'we warned the user that we updated nothing';

        _git_run( $remotegit, checkout => 'gh-pages' );
        $log = $git->run( log => -u => -n => 1 );
        my ( $remote_commit_id ) = $log =~ /commit (\S+)/;
        ok -e $remotedir->child( 'TEST_PUSH' ), 'gh-pages branch was pushed';
        is $remote_commit_id, $commit_id, 'local commit exists on remote branch';
        _git_run( $remotegit, checkout => 'master' );
    };
};

subtest 'deploy with submodules and ignored files' => sub {
    my ( $tempdir, $workdir, $remotedir ) = make_deploy( branch => 'master' );
    my $git = Git::Repository->new( work_tree => "$workdir" );

    # Add a submodule to the repo
    my $cwd = path;
    my $submoduledir = $tempdir->child('submodule');
    my $submodule = make_git( $submoduledir );
    # Add something to pull from the submodule
    $submoduledir->child( 'README' )->spurt( 'Do not commit!' );
    $submodule->run( add => 'README' );
    $submodule->run( commit => '-m' => 'add README' );

    # Git::Repository sets the "GIT_WORK_TREE" envvar, which makes most
    # submodule commands fail, so we have to unset it.
    _git_run( $git, submodule => add => "file://$submoduledir",
        { env => { GIT_WORK_TREE => undef } }
    );
    _git_run( $git, commit => '-m' => 'add submodule' );

    # Add a gitignore to the repo
    $workdir->child( '.gitignore' )->spurt( ".DS_Store\n*.swp\n" );
    $workdir->child( '.DS_Store' )->spurt( 'Do not commit!' );
    $workdir->child( 'test.swp' )->spurt( 'Do not commit!' );
    _git_run( $git, add => '.gitignore' );
    _git_run( $git, commit => '-m' => 'add gitignore' );
    _git_run( $git, push => origin => 'master' );

    # Add the same files to the build store, so that when they're deployed,
    # they would cause an error if added to the repository
    my $build_dir = $tempdir->child( 'build' );
    $build_dir->make_path;
    dircopy( $ENV{MOJO_HOME}, $build_dir );
    $build_dir->child( 'test.swp' )->spurt( 'ERROR!' );
    $build_dir->child( '.DS_Store' )->spurt( 'ERROR!' );
    $build_dir->child( 'submodule' )->make_path;
    $build_dir->child( 'submodule' => 'README' )->spurt( 'ERROR!' );
    my @build_pages = (
        @pages, 'test.swp', '.DS_Store', 'submodule/path.html',
    );

    my $deploy = Statocles::Deploy::Git->new(
        app => $t->app,
        path => $workdir,
    );
    $deploy->deploy( $ENV{MOJO_HOME} );

    eval { $deploy->deploy( $build_dir ) };
    ok !$@, 'deploy succeeds';

    my $master_commit_id = $git->run( 'rev-parse' => 'HEAD' );

    my $remotework = $tempdir->child( 'remote_work' );
    $remotework->make_path;
    my $remotegit = Git::Repository->new( git_dir => "$remotedir", work_tree => "$remotework" );

    _git_run( $remotegit, checkout => '-f' );
    for my $page ( @build_pages ) {
        # Ignored files do not get deployed
        if ( $page eq '.DS_Store' || $page eq 'test.swp' ) {
            ok !-e $remotework->child( $page ), $page . ' not deployed';
        }
        elsif ( $page =~ m{^submodule} ) {
            ok !-e $remotework->child( $page ), $page . ' not deployed';
        }
        else {
            ok -e $remotework->child( $page ), $page . ' deployed';
        }
    }
};

subtest 'deploy to subdirectory in git repo' => sub {
    my ( $tempdir, $workdir, $remotedir ) = make_deploy();

    $workdir->child( 'subdir' )->make_path;

    my $deploy = Statocles::Deploy::Git->new(
        app => $t->app,
        path => $workdir->child( 'subdir' ),
    );

    my $remotework = $tempdir->child( 'remote_work' );
    $remotework->make_path;

    my $git = Git::Repository->new( work_tree => "$workdir" );
    my $remotegit = Git::Repository->new( git_dir => "$remotedir", work_tree => "$remotework" );

    $deploy->deploy( $ENV{MOJO_HOME} );

    my $master_commit_id = $git->run( 'rev-parse' => 'HEAD' );

    _git_run( $remotegit, checkout => '-f', 'master' );
    for my $page ( @pages ) {
        ok -e $remotework->child( 'subdir' )->child( $page ),
            'subdir ' . $page . ' deployed'
                or diag explain [ $remotework->list_tree ];
    }

};

subtest '--clean' => sub {
    my ( $tempdir, $workdir, $remotedir ) = make_deploy( branch => 'gh-pages' );

    my $deploy = Statocles::Deploy::Git->new(
        app => $t->app,
        path => $workdir,
        branch => 'gh-pages',
    );

    my $remotework = $tempdir->child( 'remote_work' );
    $remotework->make_path;
    my $remotegit = Git::Repository->new( git_dir => "$remotedir", work_tree => "$remotework" );

    # Add some files that should be cleaned up
    $workdir->child( 'needs-cleaning.txt' )->spurt( 'Ha ha!' );
    my $workgit = Git::Repository->new( work_tree => "$workdir" );
    # Create the branch first
    _git_run( $workgit, checkout => '--orphan', 'gh-pages' );
    _git_run( $workgit, 'rm', '-r', '-f', '.' );
    _git_run( $workgit, add => 'needs-cleaning.txt' );
    _git_run( $workgit, commit => '-m' => 'add new file outside of site' );
    _git_run( $workgit, push => origin => 'gh-pages' );
    _git_run( $workgit, checkout => 'master' );

    subtest 'deploy without clean does not remove files' => sub {
        $deploy->deploy( $ENV{MOJO_HOME} );
        _git_run( $workgit, checkout => 'gh-pages' );
        ok -f $workdir->child( 'needs-cleaning.txt' ), 'default deploy did not remove file';
        _git_run( $workgit, checkout => 'master' );
        _git_run( $remotegit, checkout => '-f', 'gh-pages' );
        ok -f $remotework->child( 'needs-cleaning.txt' ), 'pushed to remote';
    };

    subtest 'deploy with clean removes files first' => sub {
        $deploy->deploy( $ENV{MOJO_HOME}, clean => 1 );
        _git_run( $workgit, checkout => 'gh-pages' );
        ok !-f $workdir->child( 'needs-cleaning.txt' ), 'default deploy remove files';
        _git_run( $workgit, checkout => 'master' );
        _git_run( $remotegit, checkout => '-f', 'gh-pages' );
        ok !-f $remotework->child( 'needs-cleaning.txt' ), 'pushed to remote';
    };

    subtest 'clean dies when content/deploy are sharing the same branch' => sub {
        my ( $tempdir, $workdir, $remotedir ) = make_deploy( branch => 'master' );
        my $deploy = Statocles::Deploy::Git->new(
            app => $t->app,
            path => $workdir,
            branch => 'master',
        );
        $workdir->child( qw( static.txt ) )->spurt( 'Foo' );
        eval {
            $deploy->deploy( $ENV{MOJO_HOME}, clean => 1 );
        };
        like $@, qr{\Q--clean on the same branch as deploy will destroy all content. Stopping.},
            'deploy --clean dies with an error';
        ok -f $workdir->child( qw( static.txt ) ),
            'content file /static.txt is not destroyed';
    };

};

subtest 'deploy configured with missing remote' => sub {

    subtest 'default remote "origin" does not exist' => sub {
        my ( $tempdir, $workdir, $remotedir ) = make_deploy();
        my $deploy = Statocles::Deploy::Git->new(
            app => $t->app,
            path => $workdir,
        );

        my $workgit = Git::Repository->new( work_tree => "$workdir" );
        $workgit->run( qw( remote rm origin ) );

        $deploy->deploy( $ENV{MOJO_HOME} );
        my $log = $deploy->app->log->history;
        ok scalar( grep { $_->[2] =~ qr{\QGit remote "origin" does not exist. Not pushing.} } @$log ),
            'warn user that we did not push'
                or diag explain $log;
    };

    subtest 'configured remote does not exist' => sub {
        my ( $tempdir, $workdir, $remotedir ) = make_deploy( remote => 'nondefault' );
        my $deploy = Statocles::Deploy::Git->new(
            app => $t->app,
            path => $workdir,
            remote => 'nondefault',
        );
        my $workgit = Git::Repository->new( work_tree => "$workdir" );
        $workgit->run( qw( remote rm nondefault ) );

        $deploy->deploy( $ENV{MOJO_HOME} );
        my $log = $deploy->app->log->history;
        ok scalar( grep { $_->[2] =~ qr{\QGit remote "nondefault" does not exist. Not pushing.} } @$log ),
            'warn user that we did not push'
                or diag explain $log;
    };

};

subtest 'errors' => sub {
    subtest 'not in a git repo' => sub {
        my $not_git_path = tempdir;
        my $deploy = Statocles::Deploy::Git->new(
            app => $t->app,
            path => $not_git_path,
        );

        eval { $deploy->deploy( $ENV{MOJO_HOME} ) };
        like $@, qr{Deploy path "$not_git_path" is not in a git repository\n},
            'dies with an error when not in a git repository';

    };

    subtest 'deploy from branch not yet born' => sub {
        my $tempdir = tempdir( ( CLEANUP => 0 )x!!$ENV{NO_CLEANUP} );
        my $work_git = make_git( $tempdir );
        my $deploy = Statocles::Deploy::Git->new(
            app => $t->app,
            path => $tempdir,
            branch => 'gh-pages',
        );
        eval { $deploy->deploy( $ENV{MOJO_HOME} ) };
        like $@, qr{Repository has no branches\. Please create a commit before deploying\n},
            'dies with an error when repository has no branches';
    };

};

done_testing;

sub make_git {
    my ( $dir, %args ) = @_;
    $dir->make_path;
    Git::Repository->run( "init", ( $args{bare} ? ( '--bare' ) : () ), "$dir" );
    my $git = Git::Repository->new( work_tree => "$dir" );
    # Set some config so Git knows who we are (and doesn't complain)
    _git_run( $git, config => 'user.name' => 'Statocles Test User' );
    _git_run( $git, config => 'user.email' => 'statocles@example.com' );
    return $git;
}

sub make_deploy {
    my ( %args ) = @_;
    my @temp_args;
    if ( $ENV{ NO_CLEANUP } ) {
        @temp_args = ( CLEANUP => 0 );
    }
    my $tempdir = tempdir( @temp_args );
    diag "TMP: " . $tempdir if @temp_args;

    $args{ remote } ||= "origin";
    $args{ branch } ||= "gh-pages";

    my $workdir = $tempdir->child( 'workdir' );
    my $remotedir = $tempdir->child( 'remotedir' );

    my $remotegit = make_git( $remotedir, bare => 1 );
    my $workgit = make_git( $workdir );
    _git_run( $workgit, remote => add => $args{remote} => "$remotedir" );

    # Also add a file not in the store, to test that we create an orphan branch
    $remotedir->child( "README" )->spurt( "Repository readme, not in deploy branch" );
    _git_run( $remotegit, add => 'README' );

    _git_run( $remotegit, commit => -m => 'Initial commit' );
    _git_run( $workgit, pull => $args{remote} => 'master' );

    return ( $tempdir, $workdir, $remotedir );
}

sub current_branch {
    my ( $git ) = @_;
    my @branches = map { s/^\*\s+//; $_ } grep { /^\*/ } $git->run( 'branch' );
    return $branches[0];
}


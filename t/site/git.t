
use Statocles::Test;
BEGIN {
    my $git_version = `git --version`;
    plan skip_all => 'Git not installed' unless $git_version;
    diag "Git version: $git_version";
};

use Statocles::Site::Git;
use Statocles::Theme;
use Statocles::Store;
use Statocles::App::Blog;
use File::Copy::Recursive qw( dircopy );

my $SHARE_DIR = catdir( __DIR__, '..', 'share' );

$ENV{GIT_AUTHOR_NAME} = 'preaction';
$ENV{GIT_AUTHOR_EMAIL} = 'preaction@example.com';

my @temp_args;
if ( $ENV{ NO_CLEANUP } ) {
    @temp_args = ( CLEANUP => 0 );
}

*_git_run = \&Statocles::Site::Git::_git_run;

subtest 'site writes application' => sub {
    my $tmpdir = File::Temp->newdir( @temp_args );
    diag "TMP: " . $tmpdir->dirname if @temp_args;

    my $site = site( $tmpdir );
    my $git = Git::Repository->new( work_tree => $tmpdir->dirname );

    subtest 'build' => sub {
        $site->build;

        for my $page ( $site->app( 'blog' )->pages ) {
            subtest 'page content' => test_content( $tmpdir, $site, $page, build => $page->path );
        }
    };

    subtest 'deploy' => sub {
        # Changed/added files not in the build directory do not get added
        write_file( catfile( $tmpdir->dirname, 'NEWFILE' ), 'test' );

        $site->deploy;

        is current_branch( $git ), 'master', 'deploy leaves us on the branch we came from';

        for my $page ( $site->app( 'blog' )->pages ) {
            ok !-f catfile( $tmpdir, $page->path ), 'file is not in master branch';
        }

        _git_run( $git, checkout => $site->deploy_branch );

        my $log = $git->run( log => -u => -n => 1 );
        like $log, qr{Site update};
        unlike $log, qr{NEWFILE};

        for my $page ( $site->app( 'blog' )->pages ) {
            subtest 'page content' => test_content( $tmpdir, $site, $page, '.' => $page->path );
        }
        _git_run( $git, checkout => 'master' );
    };
};

done_testing;

sub site {
    my ( $tmpdir, %site_args ) = @_;

    Git::Repository->run( init => $tmpdir->dirname );
    my $git = Git::Repository->new( work_tree => $tmpdir->dirname );

    # Copy the source into the repository, so we have something to commit
    dircopy( catdir( $SHARE_DIR, 'blog' ), catdir( $tmpdir->dirname, 'blog' ) )
        or die "Could not copy directory: $!";
    $git->run( add => 'blog' );
    $git->run( commit => -m => 'Initial commit' );

    my $theme = Statocles::Theme->new(
        source_dir => catdir( $SHARE_DIR, 'theme' ),
    );

    my $blog = Statocles::App::Blog->new(
        source => Statocles::Store->new(
            path => catdir( $tmpdir->dirname, 'blog' ),
        ),
        url_root => '/blog',
        theme => $theme,
    );

    my $site = Statocles::Site::Git->new(
        title => 'Test Site',
        apps => { blog => $blog },
        build_store => Statocles::Store->new(
            path => catdir( $tmpdir->dirname, 'build' ),
        ),
        deploy_store => Statocles::Store->new(
            path => $tmpdir->dirname,
        ),
        deploy_branch => 'gh-pages',
        %site_args,
    );

    return $site;
}

sub test_content {
    my ( $tmpdir, $site, $page, $dir, $file ) = @_;
    return sub {
        my $path = catfile( $tmpdir->dirname, $dir, $file );
        my $html = read_file( $path );
        eq_or_diff $html, $page->render( site => $site );

        like $html, qr{@{[$site->title]}}, 'page contains site title ' . $site->title;
        for my $nav ( @{ $site->nav } ) {
            my $title = $nav->{title};
            my $url = $nav->{href};
            like $html, qr{$title}, 'page contains nav title ' . $title;
            like $html, qr{$url}, 'page contains nav url ' . $url;
        }
    };
}

sub current_branch {
    my ( $git ) = @_;
    my @branches = map { s/^\*\s+//; $_ } grep { /^\*/ } $git->run( 'branch' );
    return $branches[0];
}


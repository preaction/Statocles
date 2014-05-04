
use Statocles::Test;
use Statocles::Site;
use Statocles::Theme;
use Statocles::Store;
use Statocles::App::Blog;
my $SHARE_DIR = catdir( __DIR__, 'share' );

subtest 'site' => sub {
    my $tmpdir = File::Temp->newdir;
    my $theme = Statocles::Theme->new(
        source_dir => catdir( $SHARE_DIR, 'theme' ),
    );

    my $site = Statocles::Site->new(
        apps => {
            blog => Statocles::App::Blog->new(
                source => Statocles::Store->new(
                    path => catdir( $SHARE_DIR, 'blog' ),
                ),
                destination => Statocles::Store->new(
                    path => $tmpdir->dirname,
                ),
                url_root => '/blog',
                theme => $theme,
            ),
        },
    );

    $site->deploy;

    for my $page ( $site->app( 'blog' )->pages ) {
        my $file = catfile( $tmpdir->dirname, $page->path );
        ok -f $file;
        eq_or_diff scalar read_file( $file ), $page->render;
    }
};

done_testing;


use Test::Lib;
use My::Test;
use Statocles::App::Blog;
use Statocles::Page::Document;
my $SHARE_DIR = path( __DIR__ )->parent->parent->child( 'share' );

my $site = build_test_site(
    theme => $SHARE_DIR->child( 'theme' ),
);

my $app = Statocles::App::Blog->new(
    store => $SHARE_DIR->child( 'app', 'blog' ),
    url_root => '/blog',
    site => $site,
);

subtest 'recent_posts' => sub {
    my @pages = $app->recent_posts( 2 );
    is_deeply [ map $_->path.'', @pages ], [
        '/blog/2014/06/02/more_tags/index.html',
        '/blog/2014/05/22/(regex)%5Bname%5D.file.html',
    ] or diag explain [ map { $_->path } @pages ];
};

subtest 'posts with given tag' => sub {

    subtest 'single tag (not enough posts)' => sub {
        my @pages = $app->recent_posts( 2, tags => 'more' );
        is_deeply [ map $_->path.'', @pages ], [
            '/blog/2014/06/02/more_tags/index.html',
        ] or diag explain [ map { $_->path } @pages ];
    };

};

done_testing;

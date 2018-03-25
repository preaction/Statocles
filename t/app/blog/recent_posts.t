
use Test::Lib;
use My::Test;
use Statocles::App::Blog;
use Statocles::Page::Document;
use TestStore;
my $SHARE_DIR = path( __DIR__ )->parent->parent->child( 'share' );

my $site = build_test_site(
    theme => $SHARE_DIR->child( 'theme' ),
);

my $app = Statocles::App::Blog->new(
    store => TestStore->new(
        path => $SHARE_DIR->child( qw( app blog ) ),
        objects => [
            Statocles::Document->new(
                path => '2018/01/01/post-one/index.markdown',
                tags => [qw( foo not-bar )],
            ),
            Statocles::Document->new(
                path => '2018/01/02/post-two/index.markdown',
                tags => [qw( foo )],
            ),
            Statocles::Document->new(
                path => '2018/01/03/post-three/index.markdown',
                tags => [qw( not-bar )],
            ),
        ],
    ),
    url_root => '/blog',
    site => $site,
);

subtest 'recent_posts' => sub {
    my @pages = $app->recent_posts( 2 );
    is_deeply [ map $_->path.'', @pages ], [
        '/blog/2018/01/03/post-three/index.html',
        '/blog/2018/01/02/post-two/index.html',
    ] or diag explain [ map { $_->path } @pages ];
};

subtest 'posts with given tag' => sub {

    subtest 'single tag (not enough posts)' => sub {
        my @pages = $app->recent_posts( 3, tags => 'foo' );
        is_deeply [ map $_->path.'', @pages ], [
            '/blog/2018/01/02/post-two/index.html',
            '/blog/2018/01/01/post-one/index.html',
        ] or diag explain [ map { $_->path } @pages ];
    };

};

done_testing;

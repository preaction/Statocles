
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
    cmp_deeply [ @pages ], [
        methods(
            path => Path::Tiny->new(
                qw{ blog 2014 06 02 more_tags index.html }
            )->absolute( '/' ),
        ),
        methods(
            path => Path::Tiny->new(
                qw{ blog 2014 05 22 (regex)[name].file.html }
            )->absolute( '/' ),
        ),
    ];
};

subtest 'posts with given tag' => sub {

    subtest 'single tag (not enough posts)' => sub {
        my @pages = $app->recent_posts( 2, tags => 'more' );
        cmp_deeply \@pages, [
            methods(
                path => Path::Tiny->new(
                    qw{ blog 2014 06 02 more_tags index.html }
                )->absolute( '/' ),
            ),
        ] or diag explain [ map { $_->path } @pages ];
    };

};

done_testing;

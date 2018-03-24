
use Test::Lib;
use My::Test;
use POSIX qw( locale_h );
use Statocles::App::Blog;
use Statocles::Util qw( trim );
use TestStore;
my $SHARE_DIR = path( __DIR__ )->parent->parent->child( 'share' );

my $site = build_test_site(
    theme => $SHARE_DIR->child( 'theme' ),
    base_url => 'http://example.com/',
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
            Statocles::Document->new(
                path => '2018/01/04/post-four/index.markdown',
                tags => [],
            ),
            Statocles::File->new(
                path => '2018/01/04/post-four/picture.jpg',
            ),
            Statocles::Document->new(
                path => '2018/01/04/post-four/page-2.markdown',
            ),
            Statocles::Document->new(
                path => '9999/12/31/last-post/index.markdown',
                tags => [],
            ),
        ],
    ),
    site => $site,
    url_root => '/blog',
    page_size => 2,
    index_tags => [ '-not-bar', '+foo' ],
    tag_text => {
        'foo' => 'Foo',
    },
);

my @page_tests = (

    # Index pages
    '/blog/index.html' => sub {
        my ( $page ) = @_;
        isa_ok $page, 'Statocles::Page::List';

        my @children = @{ $page->pages };
        is_deeply
            [ map { $_->path } @children ],
            [
                '/blog/2018/01/04/post-four/index.html',
                '/blog/2018/01/02/post-two/index.html',
            ],
            'child pages for main page correct';

        cmp_deeply [ map { $_->href } $page->links( 'feed' ) ],
            bag( qw(
                /blog/index.atom
                /blog/index.rss
            ) ),
            'feeds list is available';

        is $page->next, '/blog/page/2/', 'next page correct';
        ok !$page->prev, 'no prev page';

        is $page->template->path, 'blog/index.html.ep', 'template is correct';
        is $page->layout->path, 'layout/default.html.ep', 'layout is correct';
    },

    '/blog/page/2/index.html' => sub {
        my ( $page ) = @_;
        isa_ok $page, 'Statocles::Page::List';

        my @children = @{ $page->pages };
        is_deeply
            [ map { $_->path } @children ],
            [ '/blog/2018/01/01/post-one/index.html' ],
            'child pages for page 2 correct';

        cmp_deeply [ map { $_->href } $page->links( 'feed' ) ],
            bag( qw(
                /blog/index.atom
                /blog/index.rss
            ) ),
            'feeds list is available';

        ok !$page->next, 'no next page';
        is $page->prev, '/blog/', 'prev page correct';

        is $page->template->path, 'blog/index.html.ep', 'template is correct';
        is $page->layout->path, 'layout/default.html.ep', 'layout is correct';
    },

    # Index feeds
    '/blog/index.atom' => sub {
        my ( $page ) = @_;
        isa_ok $page, 'Statocles::Page::List';

        my @children = @{ $page->pages };
        is_deeply
            [ map { $_->path } @children ],
            [
                '/blog/2018/01/04/post-four/index.html',
                '/blog/2018/01/02/post-two/index.html',
            ],
            'child pages for atom feed correct';

        is $page->template->path, 'blog/index.atom.ep', 'template is correct';
        is $page->layout->content, '<%= content %>', 'layout is correct';
    },

    '/blog/index.rss' => sub {
        my ( $page ) = @_;
        isa_ok $page, 'Statocles::Page::List';

        my @children = @{ $page->pages };
        is_deeply
            [ map { $_->path } @children ],
            [
                '/blog/2018/01/04/post-four/index.html',
                '/blog/2018/01/02/post-two/index.html',
            ],
            'child pages for rss feed correct';

        is $page->template->path, 'blog/index.rss.ep', 'template is correct';
        is $page->layout->content, '<%= content %>', 'layout is correct';
    },

    # Tag pages
    '/blog/tag/foo/index.html' => sub {
        my ( $page ) = @_;
        isa_ok $page, 'Statocles::Page::List';

        my @children = @{ $page->pages };
        is_deeply
            [ map { $_->path } @children ],
            [
                '/blog/2018/01/02/post-two/index.html',
                '/blog/2018/01/01/post-one/index.html',
            ],
            'child pages for tag page correct';

        is $page->template->path, 'blog/index.html.ep', 'template is correct';
        is $page->layout->path, 'layout/default.html.ep', 'layout is correct';

        cmp_deeply [ map { $_->href } $page->links( 'feed' ) ],
            bag( qw(
                /blog/tag/foo.atom
                /blog/tag/foo.rss
            ) ),
            'feeds list is available';

        ok !$page->prev, 'no prev page';
        ok !$page->next, 'no next page';
    },

    '/blog/tag/not-bar/index.html' => sub {
        my ( $page ) = @_;
        isa_ok $page, 'Statocles::Page::List';

        my @children = @{ $page->pages };
        is_deeply
            [ map { $_->path } @children ],
            [
                '/blog/2018/01/03/post-three/index.html',
                '/blog/2018/01/01/post-one/index.html',
            ],
            'child pages for tag page correct';

        is $page->template->path, 'blog/index.html.ep', 'template is correct';
        is $page->layout->path, 'layout/default.html.ep', 'layout is correct';

        cmp_deeply [ map { $_->href } $page->links( 'feed' ) ],
            bag( qw(
                /blog/tag/not-bar.atom
                /blog/tag/not-bar.rss
            ) ),
            'feeds list is available';

        ok !$page->prev, 'no prev page';
        ok !$page->next, 'no next page';
    },

    # Tag feeds
    '/blog/tag/foo.atom' => sub {
        my ( $page ) = @_;
        isa_ok $page, 'Statocles::Page::List';

        my @children = @{ $page->pages };
        is_deeply
            [ map { $_->path } @children ],
            [
                '/blog/2018/01/02/post-two/index.html',
                '/blog/2018/01/01/post-one/index.html',
            ],
            'child pages for atom feed correct';

        is $page->template->path, 'blog/index.atom.ep', 'template is correct';
        is $page->layout->content, '<%= content %>', 'layout is correct';
    },

    '/blog/tag/foo.rss' => sub {
        my ( $page ) = @_;
        isa_ok $page, 'Statocles::Page::List';

        my @children = @{ $page->pages };
        is_deeply
            [ map { $_->path } @children ],
            [
                '/blog/2018/01/02/post-two/index.html',
                '/blog/2018/01/01/post-one/index.html',
            ],
            'child pages for rss feed correct';

        is $page->template->path, 'blog/index.rss.ep', 'template is correct';
        is $page->layout->content, '<%= content %>', 'layout is correct';
    },

    '/blog/tag/not-bar.atom' => sub {
        my ( $page ) = @_;
        isa_ok $page, 'Statocles::Page::List';

        my @children = @{ $page->pages };
        is_deeply
            [ map { $_->path } @children ],
            [
                '/blog/2018/01/03/post-three/index.html',
                '/blog/2018/01/01/post-one/index.html',
            ],
            'child pages for atom feed correct';

        is $page->template->path, 'blog/index.atom.ep', 'template is correct';
        is $page->layout->content, '<%= content %>', 'layout is correct';
    },

    '/blog/tag/not-bar.rss' => sub {
        my ( $page ) = @_;
        isa_ok $page, 'Statocles::Page::List';

        my @children = @{ $page->pages };
        is_deeply
            [ map { $_->path } @children ],
            [
                '/blog/2018/01/03/post-three/index.html',
                '/blog/2018/01/01/post-one/index.html',
            ],
            'child pages for rss feed correct';

        is $page->template->path, 'blog/index.rss.ep', 'template is correct';
        is $page->layout->content, '<%= content %>', 'layout is correct';
    },

    # Post pages
    '/blog/2018/01/01/post-one/index.html' => sub {
        my ( $page ) = @_;
        isa_ok $page, 'Statocles::Page::Document';
        is $page->document->path,
            '2018/01/01/post-one/index.markdown',
            'doc path correct';
        cmp_deeply [ map { $_->href } $page->tags ],
            bag( qw( /blog/tag/foo/ /blog/tag/not-bar/ ) ),
            'tag list is correct';
    },

    '/blog/2018/01/02/post-two/index.html' => sub {
        my ( $page ) = @_;
        isa_ok $page, 'Statocles::Page::Document';
        is $page->document->path,
            '2018/01/02/post-two/index.markdown',
            'doc path correct';
        cmp_deeply [ map { $_->href } $page->tags ],
            bag( qw( /blog/tag/foo/ ) ),
            'tag list is correct';
    },

    '/blog/2018/01/03/post-three/index.html' => sub {
        my ( $page ) = @_;
        isa_ok $page, 'Statocles::Page::Document';
        is $page->document->path,
            '2018/01/03/post-three/index.markdown',
            'doc path correct';
        cmp_deeply [ map { $_->href } $page->tags ],
            bag( qw( /blog/tag/not-bar/ ) ),
            'tag list is correct';
    },

    '/blog/2018/01/04/post-four/index.html' => sub {
        my ( $page ) = @_;
        isa_ok $page, 'Statocles::Page::Document';
        is $page->document->path,
            '2018/01/04/post-four/index.markdown',
            'doc path correct';
        cmp_deeply [ map { $_->href } $page->tags ], [ ],
            'tag list is correct';
    },

    '/blog/2018/01/04/post-four/picture.jpg' => sub {
        my ( $page ) = @_;
        isa_ok $page, 'Statocles::Page::File';
        is $page->file_path,
            $SHARE_DIR->child( qw( app blog 2018 01 04 post-four picture.jpg ) ),
            'file path correct';
    },

    '/blog/2018/01/04/post-four/page-2.html' => sub {
        my ( $page ) = @_;
        isa_ok $page, 'Statocles::Page::Document';
        is $page->document->path,
            '2018/01/04/post-four/page-2.markdown',
            'doc path correct';
        cmp_deeply [ map { $_->href } $page->tags ], [ ],
            'tag list is correct';
    },

);


test_page_objects( [ $app->pages ], @page_tests );

cmp_deeply [ map { $_->href } $app->tags ],
    bag( qw( /blog/tag/foo/ /blog/tag/not-bar/ ) ),
    'app tag list is correct'
        or diag explain [ $app->tags ];

subtest 'different locale' => sub {
    diag "Current LC_TIME locale: " . setlocale( LC_TIME );

    my $new_locale = '';
    eval {
        $new_locale = setlocale( LC_TIME, 'ru_RU' ) || '';
    };
    if ( $@ ) {
        diag "Could not set locale to ru_RU: $@";
        pass "Cannot test locale";
        return;
    }
    if ( $new_locale ne 'ru_RU' ) {
        diag "Could not set locale to ru_RU. Still $new_locale";
        pass "Cannot test locale";
        return;
    }

    test_page_objects( [ $app->pages ], @page_tests );
    is setlocale( LC_TIME ), 'ru_RU', 'locale is preserved';
    setlocale( LC_TIME, "" );
};

subtest 'blog with two posts in the same day' => sub {
    my $app = Statocles::App::Blog->new(
        store => TestStore->new(
            path => $SHARE_DIR,
            objects => [
                Statocles::Document->new(
                    path => '2016/06/01/aaa-first/index.markdown',
                    tags => [qw( mytag )],
                ),
                Statocles::Document->new(
                    path => '2016/06/01/zzz-last/index.markdown',
                    tags => [qw( mytag )],
                ),
            ],
        ),
        site => $site,
        url_root => '/',
    );
    my @pages = $app->pages;
    my ( $index ) = grep { $_->path eq '/index.html' } @pages;
    cmp_deeply [ map { $_->path.'' } @{ $index->pages } ],
        [qw( /2016/06/01/aaa-first/index.html /2016/06/01/zzz-last/index.html )],
        'index page is ordered correctly'
            or diag explain [
                map { +{ page => "".$_->path, date => "".$_->date } }
                @{ $index->pages }
            ];

    my ( $tag_page ) = grep { $_->path eq '/tag/mytag/index.html' } @pages;
    cmp_deeply [ map { $_->path.'' } @{ $tag_page->pages } ],
        [qw( /2016/06/01/aaa-first/index.html /2016/06/01/zzz-last/index.html )],
        'tag page is ordered correctly'
            or diag explain [
                map { +{ page => "".$_->path, date => "".$_->date } }
                @{ $index->pages }
            ];
};

subtest 'blog with no pages is still built' => sub {
    my $app = Statocles::App::Blog->new(
        store => TestStore->new( path => $SHARE_DIR ),
        site => $site,
        url_root => '/blog',
    );
    my @pages;
    lives_ok { @pages = $app->pages };
    cmp_deeply \@pages, [];
};

subtest 'date option' => sub {
    my @pages = $app->pages( date => '9999-12-31' );
    my ( $found ) = grep { $_->path =~ m{^/blog/9999/12/31} } @pages;
    ok $found, 'date option allows generating a post from the future';
};

done_testing;

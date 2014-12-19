
use Statocles::Base 'Test';
use Capture::Tiny qw( capture );
use Statocles::App::Blog;
my $SHARE_DIR = path( __DIR__ )->parent->child( 'share' );

my $site = Statocles::Site->new(
    title => 'Example Site',
    base_url => 'http://example.com/',
    build_store => '.'
);
local $Statocles::VERSION = '0.001';

subtest 'constructor' => sub {
    my %required = (
        store => $SHARE_DIR->child( 'blog' ),
        url_root => '/blog',
        theme => $SHARE_DIR->child( 'theme' ),
    );

    test_constructor(
        'Statocles::App::Blog',
        required => \%required,
        default => {
            page_size => 5,
            index_tags => [],
        },
    );

    subtest 'attribute types/coercions' => sub {
        subtest 'store' => sub {
            my $app = Statocles::App::Blog->new( %required );
            isa_ok $app->store, 'Statocles::Store';
            is $app->store->path, $SHARE_DIR->child( 'blog' );
        },

        subtest 'theme' => sub {
            my $app = Statocles::App::Blog->new( %required );
            isa_ok $app->theme, 'Statocles::Theme';
            is $app->theme->store->path, $SHARE_DIR->child( 'theme' );
        },

    };
};

subtest 'pages' => sub {
    my $app = Statocles::App::Blog->new(
        store => $SHARE_DIR->child( 'blog' ),
        url_root => '/blog',
        theme => $SHARE_DIR->child( 'theme' ),
        page_size => 2,
        # Remove from the index all posts tagged "better", unless they're tagged "more"
        index_tags => [ '-better', '+more', '+error message' ],
    );

    test_pages(
        $site, $app,

        # Index pages
        '/blog/index.html' => sub {
            my ( $html, $dom ) = @_;

            cmp_deeply [ $dom->find( 'h1 a' )->map( 'text' )->each ],
                [ 'More Tags', 'Regex violating Post' ],
                'first page has 2 latest post titles';

            cmp_deeply [ $dom->find( 'h1 a' )->map( attr => 'href' )->each ],
                [ '/blog/2014/06/02/more_tags.html', '/blog/2014/05/22/(regex)[name].file.html' ],
                'first page has 2 latest post paths';

            cmp_deeply [ $dom->find( '.author' )->map( 'text' )->each ],
                [ ( 'preaction' ) x 2 ],
                'author is correct';
        },

        '/blog/page-2.html' => sub {
            my ( $html, $dom ) = @_;

            cmp_deeply [ $dom->find( 'h1 a' )->map( 'text' )->each ],
                [ "First Post" ],
                'second page has earliest post';

            cmp_deeply [ $dom->find( 'h1 a' )->map( attr => 'href' )->each ],
                [ '/blog/2014/04/23/slug.html', ],
                'second page has earliest post';

            cmp_deeply [ $dom->find( '.author' )->map( 'text' )->each ],
                [ 'preaction' ],
                'author is correct';
        },

        # Index feeds
        '/blog/index.atom' => sub {
            my ( $atom, $dom ) = @_;

            is $dom->at( 'feed > id' )->text, 'http://example.com/blog/index.html';
            is $dom->at( 'feed > title' )->text, 'Example Site';
            like $dom->at( 'feed > updated' )->text, qr{^\d{4}-\d{2}-\d{2}T\d{2}:\d{2}:\d{2}Z};

            is $dom->at( 'feed > link[rel=self]' )->attr( 'href' ), 'http://example.com/blog/index.atom';
            is $dom->at( 'feed > link[rel=alternate]' )->attr( 'href' ), 'http://example.com/blog/index.html';

            is $dom->at( 'feed > generator' )->text, 'Statocles';
            is $dom->at( 'feed > generator' )->attr( 'version' ), $Statocles::VERSION;

            cmp_deeply [ $dom->find( 'entry id' )->map( 'text' )->each ],
                [
                    'http://example.com/blog/2014/06/02/more_tags.html',
                    'http://example.com/blog/2014/05/22/(regex)[name].file.html',
                ],
                'atom feed has 2 latest post paths';

            cmp_deeply [ $dom->find( 'entry title' )->map( 'text' )->each ],
                [ 'More Tags', 'Regex violating Post' ],
                'atom feed has 2 latest post titles';

            cmp_deeply [ $dom->find( 'entry author name' )->map( 'text' )->each ],
                [ ( 'preaction' ) x 2 ],
                'author is correct';

            cmp_deeply [ $dom->find( 'entry content' )->map( attr => 'type' )->each ],
                [ ( 'html' ) x 2 ],
                'content type is correct';
        },

        '/blog/index.rss' => sub {
            my ( $rss, $dom ) = @_;

            is $dom->at( 'channel > title' )->text, 'Example Site';
            is $dom->at( 'channel > link' )->text, 'http://example.com/blog/index.html';
            is $dom->at( 'channel > description' )->text, 'Blog feed of Example Site';

            is $dom->at( 'channel > link[rel=self]' )->attr( 'href' ),
                'http://example.com/blog/index.rss';

            is $dom->at( 'channel > generator' )->text, 'Statocles ' . $Statocles::VERSION;

            cmp_deeply [ $dom->find( 'item link' )->map( 'text' )->each ],
                [
                    'http://example.com/blog/2014/06/02/more_tags.html',
                    'http://example.com/blog/2014/05/22/(regex)[name].file.html',
                ],
                'rss feed has 2 latest post paths';

            cmp_deeply [ $dom->find( 'item title' )->map( 'text' )->each ],
                [ 'More Tags', 'Regex violating Post' ],
                'rss feed has 2 latest post titles';

            cmp_deeply [ $dom->find( 'item pubDate' )->map( 'text' )->each ],
                array_each( re( qr{\w{3}, \d{2} \w{3} \w{4} \d{2}:\d{2}:\d{2} [-+]\d{4}} ) ),
                'pubDate is correct';
        },

        # Tag pages
        '/blog/tag/better/index.html' => sub {
            my ( $html, $dom ) = @_;

            cmp_deeply [ $dom->find( 'h1 a' )->map( 'text' )->each ],
                [ 'More Tags', 'Regex violating Post' ],
                'first "better" page has 2 latest post titles';

            cmp_deeply [ $dom->find( 'h1 a' )->map( attr => 'href' )->each ],
                [ '/blog/2014/06/02/more_tags.html', '/blog/2014/05/22/(regex)[name].file.html' ],
                'first "better" page has 2 latest post paths';

            cmp_deeply [ $dom->find( '.author' )->map( 'text' )->each ],
                [ ( 'preaction' ) x 2 ],
                'author is correct';
        },

        '/blog/tag/better/page-2.html' => sub {
            my ( $html, $dom ) = @_;

            cmp_deeply [ $dom->find( 'h1 a' )->map( 'text' )->each ],
                [ "Second Post" ],
                'second "better" page has earlier post title';

            cmp_deeply [ $dom->find( 'h1 a' )->map( attr => 'href' )->each ],
                [ '/blog/2014/04/30/plug.html' ],
                'second "better" page has earlier post url';

            cmp_deeply [ $dom->find( '.author' )->map( 'text' )->each ],
                [ 'preaction' ],
                'author is correct';
        },

        '/blog/tag/error-message/index.html' => sub {
            my ( $html, $dom ) = @_;

            cmp_deeply [ $dom->find( 'h1 a' )->map( 'text' )->each ],
                [ 'Regex violating Post' ],
                '"error message" page has 1 post title';

            cmp_deeply [ $dom->find( 'h1 a' )->map( attr => 'href' )->each ],
                [ '/blog/2014/05/22/(regex)[name].file.html' ],
                '"error message" page has 1 post url';

            cmp_deeply [ $dom->find( '.author' )->map( 'text' )->each ],
                [ 'preaction' ],
                'author is correct';
        },

        '/blog/tag/more/index.html' => sub {
            my ( $html, $dom ) = @_;

            cmp_deeply [ $dom->find( 'h1 a' )->map( 'text' )->each ],
                [ 'More Tags' ],
                '"more" page has 1 post title';

            cmp_deeply [ $dom->find( 'h1 a' )->map( attr => 'href' )->each ],
                [ '/blog/2014/06/02/more_tags.html', ],
                '"more" page has 1 post url';

            cmp_deeply [ $dom->find( '.author' )->map( 'text' )->each ],
                [ 'preaction' ],
                'author is correct';
        },

        '/blog/tag/even-more-tags/index.html' => sub {
            my ( $html, $dom ) = @_;

            cmp_deeply [ $dom->find( 'h1 a' )->map( 'text' )->each ],
                [ 'More Tags' ],
                '"even more tags" page has 1 post title';

            cmp_deeply [ $dom->find( 'h1 a' )->map( attr => 'href' )->each ],
                [ '/blog/2014/06/02/more_tags.html', ],
                '"even more tags" page has 1 post url';

            cmp_deeply [ $dom->find( '.author' )->map( 'text' )->each ],
                [ 'preaction' ],
                'author is correct';
        },

        # Tag feeds
        '/blog/tag/better.atom' => sub {
            my ( $atom, $dom ) = @_;

            is $dom->at( 'feed > id' )->text, 'http://example.com/blog/tag/better/index.html';
            is $dom->at( 'feed > title' )->text, 'Example Site';
            like $dom->at( 'feed > updated' )->text, qr{^\d{4}-\d{2}-\d{2}T\d{2}:\d{2}:\d{2}Z};

            is $dom->at( 'feed > link[rel=self]' )->attr( 'href' ),
                'http://example.com/blog/tag/better.atom';
            is $dom->at( 'feed > link[rel=alternate]' )->attr( 'href' ),
                'http://example.com/blog/tag/better/index.html';

            is $dom->at( 'feed > generator' )->text, 'Statocles';
            is $dom->at( 'feed > generator' )->attr( 'version' ), $Statocles::VERSION;

            cmp_deeply [ $dom->find( 'entry id' )->map( 'text' )->each ],
                [
                    'http://example.com/blog/2014/06/02/more_tags.html',
                    'http://example.com/blog/2014/05/22/(regex)[name].file.html',
                ],
                'atom feed has 2 latest post paths';

            cmp_deeply [ $dom->find( 'entry title' )->map( 'text' )->each ],
                [ 'More Tags', 'Regex violating Post' ],
                'atom feed has 2 latest post titles';

            cmp_deeply [ $dom->find( 'entry author name' )->map( 'text' )->each ],
                [ ( 'preaction' ) x 2 ],
                'author is correct';

            cmp_deeply [ $dom->find( 'entry content' )->map( attr => 'type' )->each ],
                [ ( 'html' ) x 2 ],
                'content type is correct';
        },

        '/blog/tag/better.rss' => sub {
            my ( $rss, $dom ) = @_;

            is $dom->at( 'channel > title' )->text, 'Example Site';
            is $dom->at( 'channel > link' )->text, 'http://example.com/blog/tag/better/index.html';
            is $dom->at( 'channel > description' )->text, 'Blog feed of Example Site';

            is $dom->at( 'channel > link[rel=self]' )->attr( 'href' ),
                'http://example.com/blog/tag/better.rss';

            is $dom->at( 'channel > generator' )->text, 'Statocles ' . $Statocles::VERSION;

            cmp_deeply [ $dom->find( 'item link' )->map( 'text' )->each ],
                [
                    'http://example.com/blog/2014/06/02/more_tags.html',
                    'http://example.com/blog/2014/05/22/(regex)[name].file.html',
                ],
                'rss feed has 2 latest post paths';

            cmp_deeply [ $dom->find( 'item title' )->map( 'text' )->each ],
                [ 'More Tags', 'Regex violating Post' ],
                'rss feed has 2 latest post titles';

            cmp_deeply [ $dom->find( 'item pubDate' )->map( 'text' )->each ],
                array_each( re( qr{\w{3}, \d{2} \w{3} \w{4} \d{2}:\d{2}:\d{2} [-+]\d{4}} ) ),
                'pubDate is correct';
        },

        '/blog/tag/error-message.atom' => sub {
            my ( $atom, $dom ) = @_;

            is $dom->at( 'feed > id' )->text,
                'http://example.com/blog/tag/error-message/index.html';
            is $dom->at( 'feed > title' )->text, 'Example Site';
            like $dom->at( 'feed > updated' )->text,
                qr{^\d{4}-\d{2}-\d{2}T\d{2}:\d{2}:\d{2}Z};

            is $dom->at( 'feed > link[rel=self]' )->attr( 'href' ),
                'http://example.com/blog/tag/error-message.atom';
            is $dom->at( 'feed > link[rel=alternate]' )->attr( 'href' ),
                'http://example.com/blog/tag/error-message/index.html';

            is $dom->at( 'feed > generator' )->text, 'Statocles';
            is $dom->at( 'feed > generator' )->attr( 'version' ), $Statocles::VERSION;

            cmp_deeply [ $dom->find( 'entry id' )->map( 'text' )->each ],
                [
                    'http://example.com/blog/2014/05/22/(regex)[name].file.html',
                ],
                'atom feed has correct post paths';

            cmp_deeply [ $dom->find( 'entry title' )->map( 'text' )->each ],
                [ 'Regex violating Post' ],
                'atom feed has correct post paths';

            cmp_deeply [ $dom->find( 'entry author name' )->map( 'text' )->each ],
                [ 'preaction' ],
                'author is correct';

            cmp_deeply [ $dom->find( 'entry content' )->map( attr => 'type' )->each ],
                [ 'html' ],
                'content type is correct';
        },

        '/blog/tag/error-message.rss' => sub {
            my ( $rss, $dom ) = @_;

            is $dom->at( 'channel > title' )->text, 'Example Site';
            is $dom->at( 'channel > link' )->text, 'http://example.com/blog/tag/error-message/index.html';
            is $dom->at( 'channel > description' )->text, 'Blog feed of Example Site';

            is $dom->at( 'channel > link[rel=self]' )->attr( 'href' ),
                'http://example.com/blog/tag/error-message.rss';

            is $dom->at( 'channel > generator' )->text, 'Statocles ' . $Statocles::VERSION;

            cmp_deeply [ $dom->find( 'item link' )->map( 'text' )->each ],
                [
                    'http://example.com/blog/2014/05/22/(regex)[name].file.html',
                ],
                'rss feed has correct post paths';

            cmp_deeply [ $dom->find( 'item title' )->map( 'text' )->each ],
                [ 'Regex violating Post' ],
                'rss feed has correct post titles';

            cmp_deeply [ $dom->find( 'item pubDate' )->map( 'text' )->each ],
                array_each( re( qr{\w{3}, \d{2} \w{3} \w{4} \d{2}:\d{2}:\d{2} [-+]\d{4}} ) ),
                'pubDate is correct';
        },

        '/blog/tag/more.atom' => sub {
            my ( $atom, $dom ) = @_;

            is $dom->at( 'feed > id' )->text,
                'http://example.com/blog/tag/more/index.html';
            is $dom->at( 'feed > title' )->text, 'Example Site';
            like $dom->at( 'feed > updated' )->text,
                qr{^\d{4}-\d{2}-\d{2}T\d{2}:\d{2}:\d{2}Z};

            is $dom->at( 'feed > link[rel=self]' )->attr( 'href' ),
                'http://example.com/blog/tag/more.atom';
            is $dom->at( 'feed > link[rel=alternate]' )->attr( 'href' ),
                'http://example.com/blog/tag/more/index.html';

            is $dom->at( 'feed > generator' )->text, 'Statocles';
            is $dom->at( 'feed > generator' )->attr( 'version' ), $Statocles::VERSION;

            cmp_deeply [ $dom->find( 'entry id' )->map( 'text' )->each ],
                [
                    'http://example.com/blog/2014/06/02/more_tags.html',
                ],
                'atom feed has correct post paths';

            cmp_deeply [ $dom->find( 'entry title' )->map( 'text' )->each ],
                [ 'More Tags' ],
                'atom feed has correct post titles';

            cmp_deeply [ $dom->find( 'entry author name' )->map( 'text' )->each ],
                [ 'preaction' ],
                'author is correct';

            cmp_deeply [ $dom->find( 'entry content' )->map( attr => 'type' )->each ],
                [ 'html' ],
                'content type is correct';
        },

        '/blog/tag/more.rss' => sub {
            my ( $rss, $dom ) = @_;

            is $dom->at( 'channel > title' )->text, 'Example Site';
            is $dom->at( 'channel > link' )->text, 'http://example.com/blog/tag/more/index.html';
            is $dom->at( 'channel > description' )->text, 'Blog feed of Example Site';

            is $dom->at( 'channel > link[rel=self]' )->attr( 'href' ),
                'http://example.com/blog/tag/more.rss';

            is $dom->at( 'channel > generator' )->text, 'Statocles ' . $Statocles::VERSION;

            cmp_deeply [ $dom->find( 'item link' )->map( 'text' )->each ],
                [
                    'http://example.com/blog/2014/06/02/more_tags.html',
                ],
                'rss feed has correct post paths';

            cmp_deeply [ $dom->find( 'item title' )->map( 'text' )->each ],
                [ 'More Tags' ],
                'rss feed has correct post titles';

            cmp_deeply [ $dom->find( 'item pubDate' )->map( 'text' )->each ],
                array_each( re( qr{\w{3}, \d{2} \w{3} \w{4} \d{2}:\d{2}:\d{2} [-+]\d{4}} ) ),
                'pubDate is correct';
        },

        '/blog/tag/even-more-tags.atom' => sub {
            my ( $atom, $dom ) = @_;

            is $dom->at( 'feed > id' )->text,
                'http://example.com/blog/tag/even-more-tags/index.html';
            is $dom->at( 'feed > title' )->text, 'Example Site';
            like $dom->at( 'feed > updated' )->text,
                qr{^\d{4}-\d{2}-\d{2}T\d{2}:\d{2}:\d{2}Z};

            is $dom->at( 'feed > link[rel=self]' )->attr( 'href' ),
                'http://example.com/blog/tag/even-more-tags.atom';
            is $dom->at( 'feed > link[rel=alternate]' )->attr( 'href' ),
                'http://example.com/blog/tag/even-more-tags/index.html';

            is $dom->at( 'feed > generator' )->text, 'Statocles';
            is $dom->at( 'feed > generator' )->attr( 'version' ), $Statocles::VERSION;

            cmp_deeply [ $dom->find( 'entry id' )->map( 'text' )->each ],
                [
                    'http://example.com/blog/2014/06/02/more_tags.html',
                ],
                'atom feed has correct post paths';

            cmp_deeply [ $dom->find( 'entry title' )->map( 'text' )->each ],
                [ 'More Tags' ],
                'atom feed has correct post titles';

            cmp_deeply [ $dom->find( 'entry author name' )->map( 'text' )->each ],
                [ 'preaction' ],
                'author is correct';

            cmp_deeply [ $dom->find( 'entry content' )->map( attr => 'type' )->each ],
                [ 'html' ],
                'content type is correct';
        },

        '/blog/tag/even-more-tags.rss' => sub {
            my ( $rss, $dom ) = @_;

            is $dom->at( 'channel > title' )->text, 'Example Site';
            is $dom->at( 'channel > link' )->text,
                'http://example.com/blog/tag/even-more-tags/index.html';
            is $dom->at( 'channel > description' )->text, 'Blog feed of Example Site';

            is $dom->at( 'channel > link[rel=self]' )->attr( 'href' ),
                'http://example.com/blog/tag/even-more-tags.rss';

            is $dom->at( 'channel > generator' )->text, 'Statocles ' . $Statocles::VERSION;

            cmp_deeply [ $dom->find( 'item link' )->map( 'text' )->each ],
                [
                    'http://example.com/blog/2014/06/02/more_tags.html',
                ],
                'rss feed has right post links';

            cmp_deeply [ $dom->find( 'item title' )->map( 'text' )->each ],
                [ 'More Tags' ],
                'rss feed has right post titles';

            cmp_deeply [ $dom->find( 'item pubDate' )->map( 'text' )->each ],
                array_each( re( qr{\w{3}, \d{2} \w{3} \w{4} \d{2}:\d{2}:\d{2} [-+]\d{4}} ) ),
                'pubDate is correct';
        },

        # Post pages
        '/blog/2014/04/23/slug.html' => sub {
            my ( $html, $dom ) = @_;

            is $dom->at( 'header h1' )->text, 'First Post';
            is $dom->at( '.author' )->text, 'preaction';
            ok !scalar $dom->find( 'header .tags a' )->each, 'no tags';

            # crosspost, blogs.perl.org, http://blogs.perl.org/preaction/404.html
            is $dom->at( '.crosspost a' )->attr( 'href' ),
                'http://blogs.perl.org/preaction/404.html';
            is $dom->at( '.crosspost a em' )->text, 'First Post';
            is $dom->at( '.crosspost a' )->text, 'on blogs.perl.org.';
        },

        '/blog/2014/04/30/plug.html' => sub {
            my ( $html, $dom ) = @_;

            is $dom->at( 'header h1' )->text, 'Second Post';
            is $dom->at( '.author' )->text, 'preaction';

            cmp_deeply [ $dom->find( '.tags a' )->map( 'text' )->each ],
                [ 'better' ];
            cmp_deeply [ $dom->find( '.tags a' )->map( attr => 'href' )->each ],
                [ '/blog/tag/better/index.html' ];

            ok !scalar $dom->find( '.crosspost' )->each, 'no crosspost';
        },

        '/blog/2014/05/22/(regex)[name].file.html' => sub {
            my ( $html, $dom ) = @_;

            is $dom->at( 'header h1' )->text, 'Regex violating Post';
            is $dom->at( '.author' )->text, 'preaction';

            cmp_deeply [ $dom->find( '.tags a' )->map( 'text' )->each ],
                bag( 'better', 'error message' );
            cmp_deeply [ $dom->find( '.tags a' )->map( attr => 'href' )->each ],
                bag(
                    '/blog/tag/better/index.html',
                    '/blog/tag/error-message/index.html',
                );

            ok !scalar $dom->find( '.crosspost' )->each, 'no crosspost';
        },

        '/blog/2014/06/02/more_tags.html' => sub {
            my ( $html, $dom ) = @_;

            is $dom->at( 'header h1' )->text, 'More Tags';
            is $dom->at( '.author' )->text, 'preaction';

            cmp_deeply [ $dom->find( '.tags a' )->map( 'text' )->each ],
                bag( 'more', 'better', 'even more tags' );
            cmp_deeply [ $dom->find( '.tags a' )->map( attr => 'href' )->each ],
                bag(
                    '/blog/tag/more/index.html',
                    '/blog/tag/better/index.html',
                    '/blog/tag/even-more-tags/index.html',
                );

            # crosspost, blogs.perl.org, http://blogs.perl.org/preaction/404.html
            is $dom->at( '.crosspost a' )->attr( 'href' ),
                'http://blogs.perl.org/preaction/404.html';
            is $dom->at( '.crosspost a em' )->text, 'More Tags';
            is $dom->at( '.crosspost a' )->text, 'on blogs.perl.org.';
        },

        # Does not show /blog/9999/12/31/forever-is-a-long-time.html
        # Does not show /blog/draft/a-draft-post.html
    );
};

subtest 'commands' => sub {
    # We need an app we can edit
    my $tmpdir = tempdir;
    my $app = Statocles::App::Blog->new(
        store => $tmpdir->child( 'blog' ),
        url_root => '/blog',
        theme => $SHARE_DIR->child( 'theme' ),
    );

    subtest 'errors' => sub {
        subtest 'invalid command' => sub {
            my @args = qw( blog foo );
            my ( $out, $err, $exit ) = capture { $app->command( @args ) };
            ok !$out, 'blog error is on stderr' or diag $out;
            isnt $exit, 0;
            like $err, qr{\QERROR: Unknown command "foo"}, "contains error message";
            like $err, qr{\Qblog post [--date YYYY-MM-DD] <title> -- Create a new blog post},
                'contains blog usage information';
        };

        subtest 'missing command' => sub {
            my @args = qw( blog );
            my ( $out, $err, $exit ) = capture { $app->command( @args ) };
            ok !$out, 'blog error is on stderr' or diag $out;
            isnt $exit, 0;
            like $err, qr{\QERROR: Missing command}, "contains error message";
            like $err, qr{\Qblog post [--date YYYY-MM-DD] <title> -- Create a new blog post},
                'contains blog usage information';
        };
    };

    subtest 'help' => sub {
        my @args = qw( blog help );
        my ( $out, $err, $exit ) = capture { $app->command( @args ) };
        ok !$err, 'blog help is on stdout';
        is $exit, 0;
        like $out, qr{\Qblog post [--date YYYY-MM-DD] <title> -- Create a new blog post},
            'contains blog help information';
    };

    subtest 'post' => sub {
        subtest 'create new post' => sub {
            subtest 'without $EDITOR, title is required' => sub {
                local $ENV{EDITOR};
                my @args = qw( blog post );
                my ( $out, $err, $exit ) = capture { $app->command( @args ) };
                like $err, qr{Title is required when \$EDITOR is not set};
                like $err, qr{blog post <title>};
                isnt $exit, 0;
            };

            subtest 'default document' => sub {
                local $ENV{EDITOR}; # We can't very well open vim...
                my ( undef, undef, undef, $day, $mon, $year ) = localtime;
                my $doc_path = $tmpdir->child(
                    'blog',
                    sprintf( '%04i', $year + 1900 ),
                    sprintf( '%02i', $mon + 1 ),
                    sprintf( '%02i', $day ),
                    'this-is-a-title.yml',
                );

                subtest 'run the command' => sub {
                    my @args = qw( blog post This is a Title );
                    my ( $out, $err, $exit ) = capture { $app->command( @args ) };
                    ok !$err, 'nothing on stdout';
                    is $exit, 0;
                    like $out, qr{New post at: \Q$doc_path},
                        'contains blog post document path';
                };

                subtest 'check the generated document' => sub {
                    my $doc = $app->store->read_document( $doc_path->relative( $tmpdir->child('blog') ) );
                    cmp_deeply $doc, {
                        title => 'This is a Title',
                        author => undef,
                        tags => undef,
                        last_modified => isa( 'Time::Piece' ),
                        content => <<'ENDMARKDOWN',
Markdown content goes here.
ENDMARKDOWN
                    };
                    my $dt_str = $doc->{last_modified}->strftime( '%Y-%m-%d %H:%M:%S' );
                    eq_or_diff $doc_path->slurp, <<ENDCONTENT;
---
author: ~
last_modified: $dt_str
tags: ~
title: This is a Title
---
Markdown content goes here.
ENDCONTENT
                };
            };
            subtest 'custom date' => sub {
                local $ENV{EDITOR}; # We can't very well open vim...

                my $doc_path = $tmpdir->child(
                    'blog', '2014', '04', '01', 'this-is-a-title.yml',
                );

                subtest 'run the command' => sub {
                    my @args = qw( blog post --date 2014-4-1 This is a Title );
                    my ( $out, $err, $exit ) = capture { $app->command( @args ) };
                    ok !$err, 'nothing on stdout';
                    is $exit, 0;
                    like $out, qr{New post at: \Q$doc_path},
                        'contains blog post document path';
                };

                subtest 'check the generated document' => sub {
                    my $doc = $app->store->read_document( $doc_path->relative( $tmpdir->child( 'blog' ) ) );
                    cmp_deeply $doc, {
                        title => 'This is a Title',
                        author => undef,
                        tags => undef,
                        last_modified => isa( 'Time::Piece' ),
                        content => <<'ENDMARKDOWN',
Markdown content goes here.
ENDMARKDOWN
                    };
                    my $dt_str = $doc->{last_modified}->strftime( '%Y-%m-%d %H:%M:%S' );
                    eq_or_diff $doc_path->slurp, <<ENDCONTENT;
---
author: ~
last_modified: $dt_str
tags: ~
title: This is a Title
---
Markdown content goes here.
ENDCONTENT
                };
            };
        };
    };
};

done_testing;

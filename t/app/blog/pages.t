
use Test::Lib;
use My::Test;
use POSIX qw( locale_h );
use Statocles::App::Blog;
my $SHARE_DIR = path( __DIR__ )->parent->parent->child( 'share' );

my $site = build_test_site(
    theme => $SHARE_DIR->child( 'theme' ),
    base_url => 'http://example.com/',
);

my $app = Statocles::App::Blog->new(
    store => $SHARE_DIR->child( qw( app blog ) ),
    site => $site,
    url_root => '/blog',
    page_size => 2,
    # Remove from the index all posts tagged "better", unless they're tagged "more"
    index_tags => [ '-better', '+more', '+error message' ],
    data => {
        info => 'This is the app info',
    },
    tag_text => {
        'error message' => 'These are error messages',
    },
);

my @page_tests = (

    # Index pages
    '/blog/index.html' => sub {
        my ( $html, $dom ) = @_;

        cmp_deeply [ $dom->find( 'h1 a' )->map( 'text' )->each ],
            [ 'More Tags', 'Regex violating Post' ],
            'first page has 2 latest post titles';

        cmp_deeply [ $dom->find( 'h1 a' )->map( attr => 'href' )->each ],
            [ '/blog/2014/06/02/more_tags/', '/blog/2014/05/22/(regex)[name].file.html' ],
            'first page has 2 latest post paths';

        cmp_deeply [ $dom->find( '.author' )->map( 'text' )->each ],
            [ 'preaction' ],
            'author is correct';

        cmp_deeply [ $dom->find( 'img' )->map( attr => 'src' )->each ],
            superbagof( '/blog/2014/06/02/more_tags/image.markdown.jpg' ),
            'relative image is fixed on list page';

        cmp_deeply [ $dom->find( 'a' )->map( attr => 'href' )->each ],
            superbagof( '/blog/2014/06/02/more_tags/docs.html' ),
            'relative link is fixed on list page';

        subtest 'links on more_tags page are rewritten correctly' => sub {
            my %links = (
                # TEXT => URL
                "Body Content" => '/does_not_exist',
                "relative" => '/blog/2014/06/02/more_tags/does_not_exist',
                "Broken link with URL encoding" => '/images/with%20spaces.png',
                "Working link with URL encoding" => '/blog/2014/05/22/%28regex%29%5Bname%5D.file.html',
                "Full URLs are not broken" => 'http://example.com',
                "Full URLs without schema are not broken" => '//example.com',
                "Fixed relative URL" => '/blog/2014/06/02/more_tags/docs.html',
                "Test a mailto: link" => 'mailto:user@example.com',
            );
            my @links = $dom->find( 'article .content a' )->each;
            is scalar @links, scalar keys %links, 'all links found';
            for my $link ( @links ) {
                is $link->attr( 'href' ), $links{ $link->text }, 'link href is correct: ' . $link->text;
            }
        };

        cmp_deeply [ $dom->find( '.tags a' )->map( attr => 'href' )->each ],
            bag( qw(
                /blog/tag/better/
                /blog/tag/error-message/
                /blog/tag/more/
                /blog/tag/even-more-tags/
            ) ),
            'tag list is available';

        cmp_deeply [ $dom->find( '.feeds a' )->map( attr => 'href' )->each ],
            bag( qw(
                /blog/index.atom
                /blog/index.rss
            ) ),
            'feeds list is available';

        if ( ok my $node = $dom->at( 'footer #app-info' ) ) {
            is $node->text, $app->data->{info}, 'app-info is correct';
        }

        my $prev = $dom->at( '.pager .prev' );
        is $prev->at( 'a' )->attr( 'class' ), 'button button-primary';
        is $prev->at( 'a' )->attr( 'href' ), '/blog/page/2';

        my $next = $dom->at( '.pager .next' );
        is $next->at( 'a' )->attr( 'class' ), 'button disabled';
        is $next->at( 'a' )->attr( 'href' ), '';
    },

    '/blog/page/2/index.html' => sub {
        my ( $html, $dom ) = @_;

        cmp_deeply [ $dom->find( 'h1 a' )->map( 'text' )->each ],
            [ "First Post" ],
            'second page has earliest post';

        cmp_deeply [ $dom->find( 'h1 a' )->map( attr => 'href' )->each ],
            [ '/blog/2014/04/23/slug/', ],
            'second page has earliest post';

        cmp_deeply [ $dom->find( '.author' )->map( 'text' )->each ],
            [ 'preaction' ],
            'author is correct';

        cmp_deeply [ $dom->find( '.tags a' )->map( attr => 'href' )->each ],
            bag( qw(
                /blog/tag/better/
                /blog/tag/error-message/
                /blog/tag/more/
                /blog/tag/even-more-tags/
            ) ),
            'tag list is available';

        cmp_deeply [ $dom->find( '.feeds a' )->map( attr => 'href' )->each ],
            bag( qw(
                /blog/index.atom
                /blog/index.rss
            ) ),
            'feeds list is available';

        if ( ok my $node = $dom->at( 'footer #app-info' ) ) {
            is $node->text, $app->data->{info}, 'app-info is correct';
        }

        my $prev = $dom->at( '.pager .prev' );
        is $prev->at( 'a' )->attr( 'class' ), 'button disabled';
        is $prev->at( 'a' )->attr( 'href' ), '';

        my $next = $dom->at( '.pager .next' );
        is $next->at( 'a' )->attr( 'class' ), 'button button-primary';
        is $next->at( 'a' )->attr( 'href' ), '/blog';
    },

    # Index feeds
    '/blog/index.atom' => sub {
        my ( $atom, $dom ) = @_;

        is $dom->at( 'feed > id' )->text, 'http://example.com/blog/';
        is $dom->at( 'feed > title' )->text, 'Example Site';
        like $dom->at( 'feed > updated' )->text, qr{^\d{4}-\d{2}-\d{2}T\d{2}:\d{2}:\d{2}Z};

        is $dom->at( 'feed > link[rel=self]' )->attr( 'href' ), 'http://example.com/blog/index.atom';
        is $dom->at( 'feed > link[rel=alternate]' )->attr( 'href' ), 'http://example.com/blog/';

        is $dom->at( 'feed > generator' )->text, 'Statocles';
        is $dom->at( 'feed > generator' )->attr( 'version' ), $Statocles::VERSION;

        cmp_deeply [ $dom->find( 'entry id' )->map( 'text' )->each ],
            [
                'http://example.com/blog/2014/06/02/more_tags/',
                'http://example.com/blog/2014/05/22/(regex)[name].file.html',
            ],
            'atom feed has 2 latest post paths';

        cmp_deeply [ $dom->find( 'entry title' )->map( 'text' )->each ],
            [ 'More Tags', 'Regex violating Post' ],
            'atom feed has 2 latest post titles';

        cmp_deeply [ $dom->find( 'entry author name' )->map( 'text' )->each ],
            [ 'preaction' ],
            'author is correct';

        cmp_deeply [ $dom->find( 'entry content' )->map( attr => 'type' )->each ],
            [ ( 'html' ) x 2 ],
            'content type is correct';

        cmp_deeply [ $dom->find( 'entry category' )->map( attr => 'term' )->each ],
            [ 'more', 'better', 'even more tags', 'better', 'error message' ],
            'categories are correct';

        my $content_dom = Mojo::DOM->new( $dom->at( 'entry:first-of-type content' )->text );
        cmp_deeply [ $content_dom->find( 'img' )->map( attr => 'src' )->each ],
            superbagof( 'http://example.com/blog/2014/06/02/more_tags/image.markdown.jpg' ),
            'relative image is fixed on feed page';

        cmp_deeply [ $content_dom->find( 'a' )->map( attr => 'href' )->each ],
            superbagof( 'http://example.com/blog/2014/06/02/more_tags/docs.html' ),
            'relative link is fixed on feed page';

        my @posts = $dom->find( 'entry content' )
                    ->map( sub { Mojo::DOM->new( shift->child_nodes->first->content ) } )
                    ->each;

        is scalar @posts, 2, 'a full page of posts';
        for my $post ( @posts ) {
            for my $link ( $post->find( 'a[href]' )->each ) {
                like $link->attr( 'href' ), qr{^(?:http:|mailto:|//)}, 'all urls in feed are full';
            }
        }
    },

    '/blog/index.rss' => sub {
        my ( $rss, $dom ) = @_;

        is $dom->at( 'channel > title' )->text, 'Example Site';
        is $dom->at( 'channel > link' )->text, 'http://example.com/blog/';
        is $dom->at( 'channel > description' )->text, 'Blog feed of Example Site';

        is $dom->at( 'channel > link[rel=self]' )->attr( 'href' ),
            'http://example.com/blog/index.rss';

        is $dom->at( 'channel > generator' )->text, 'Statocles ' . $Statocles::VERSION;

        cmp_deeply [ $dom->find( 'item link' )->map( 'text' )->each ],
            [
                'http://example.com/blog/2014/06/02/more_tags/',
                'http://example.com/blog/2014/05/22/(regex)[name].file.html',
            ],
            'rss feed has 2 latest post paths';

        cmp_deeply [ $dom->find( 'item title' )->map( 'text' )->each ],
            [ 'More Tags', 'Regex violating Post' ],
            'rss feed has 2 latest post titles';

        cmp_deeply [ $dom->find( 'item pubDate' )->map( 'text' )->each ],
            array_each( re( qr{\w{3}, \d{2} \w{3} \w{4} \d{2}:\d{2}:\d{2} [-+]\d{4}} ) ),
            'pubDate is correct';

        my @posts = $dom->find( 'item description' )
                    ->map( sub { Mojo::DOM->new( $_[0]->child_nodes->first->content ) } )
                    ->each;

        is scalar @posts, 2, 'a full page of posts';
        for my $post ( @posts ) {
            for my $link ( $post->find( 'a[href]' )->each ) {
                like $link->attr( 'href' ), qr{^(?:http:|mailto:|//)}, 'all urls in feed are full';
            }
        }
    },

    # Tag pages
    '/blog/tag/better/index.html' => sub {
        my ( $html, $dom ) = @_;

        cmp_deeply [ $dom->find( 'h1 a' )->map( 'text' )->each ],
            [ 'More Tags', 'Regex violating Post' ],
            'first "better" page has 2 latest post titles';

        cmp_deeply [ $dom->find( 'h1 a' )->map( attr => 'href' )->each ],
            [ '/blog/2014/06/02/more_tags/', '/blog/2014/05/22/(regex)[name].file.html' ],
            'first "better" page has 2 latest post paths';

        cmp_deeply [ $dom->find( '.author' )->map( 'text' )->each ],
            [ 'preaction' ],
            'author is correct';

        cmp_deeply [ $dom->find( '.tags a' )->map( attr => 'href' )->each ],
            bag( qw(
                /blog/tag/better/
                /blog/tag/error-message/
                /blog/tag/more/
                /blog/tag/even-more-tags/
            ) ),
            'tag list is available';

        cmp_deeply [ $dom->find( '.feeds a' )->map( attr => 'href' )->each ],
            bag( qw(
                /blog/tag/better.atom
                /blog/tag/better.rss
            ) ),
            'feeds list is available';

        if ( ok my $node = $dom->at( 'footer #app-info' ) ) {
            is $node->text, $app->data->{info}, 'app-info is correct';
        }

        my $prev = $dom->at( '.pager .prev' );
        is $prev->at( 'a' )->attr( 'class' ), 'button button-primary';
        is $prev->at( 'a' )->attr( 'href' ), '/blog/tag/better/page/2';

        my $next = $dom->at( '.pager .next' );
        is $next->at( 'a' )->attr( 'class' ), 'button disabled';
        is $next->at( 'a' )->attr( 'href' ), '';
    },

    '/blog/tag/better/page/2/index.html' => sub {
        my ( $html, $dom ) = @_;

        cmp_deeply [ $dom->find( 'h1 a' )->map( 'text' )->each ],
            [ "Second Post" ],
            'second "better" page has earlier post title';

        cmp_deeply [ $dom->find( 'h1 a' )->map( attr => 'href' )->each ],
            [ '/blog/2014/04/30/plug/' ],
            'second "better" page has earlier post url';

        cmp_deeply [ $dom->find( 'img' )->map( attr => 'src' )->each ],
            superbagof( '/blog/2014/04/30/plug/image.jpg' ),
            'relative image is fixed on list page';

        cmp_deeply [ $dom->find( 'a' )->map( attr => 'href' )->each ],
            superbagof( '/blog/2014/04/30/plug/recipe.html' ),
            'relative link is fixed on list page';

        cmp_deeply [ $dom->find( '.author' )->map( 'text' )->each ],
            [ 'preaction' ],
            'author is correct';

        cmp_deeply [ $dom->find( '.tags a' )->map( attr => 'href' )->each ],
            bag( qw(
                /blog/tag/better/
                /blog/tag/error-message/
                /blog/tag/more/
                /blog/tag/even-more-tags/
            ) ),
            'tag list is available';

        cmp_deeply [ $dom->find( '.feeds a' )->map( attr => 'href' )->each ],
            bag( qw(
                /blog/tag/better.atom
                /blog/tag/better.rss
            ) ),
            'feeds list is available';

        if ( ok my $node = $dom->at( 'footer #app-info' ) ) {
            is $node->text, $app->data->{info}, 'app-info is correct';
        }

        my $prev = $dom->at( '.pager .prev' );
        is $prev->at( 'a' )->attr( 'class' ), 'button disabled';
        is $prev->at( 'a' )->attr( 'href' ), '';

        my $next = $dom->at( '.pager .next' );
        is $next->at( 'a' )->attr( 'class' ), 'button button-primary';
        is $next->at( 'a' )->attr( 'href' ), '/blog/tag/better';
    },

    '/blog/tag/error-message/index.html' => sub {
        my ( $html, $dom ) = @_;

        like $html, qr{These are error messages}, 'has tag description';

        cmp_deeply [ $dom->find( 'h1 a' )->map( 'text' )->each ],
            [ 'Regex violating Post' ],
            '"error message" page has 1 post title';

        cmp_deeply [ $dom->find( 'h1 a' )->map( attr => 'href' )->each ],
            [ '/blog/2014/05/22/(regex)[name].file.html' ],
            '"error message" page has 1 post url';

        cmp_deeply [ $dom->find( '.author' )->map( 'text' )->each ],
            [ 'preaction' ],
            'author is correct';

        cmp_deeply [ $dom->find( '.tags a' )->map( attr => 'href' )->each ],
            bag( qw(
                /blog/tag/better/
                /blog/tag/error-message/
                /blog/tag/more/
                /blog/tag/even-more-tags/
            ) ),
            'tag list is available';

        cmp_deeply [ $dom->find( '.feeds a' )->map( attr => 'href' )->each ],
            bag( qw(
                /blog/tag/error-message.atom
                /blog/tag/error-message.rss
            ) ),
            'feeds list is available';

        if ( ok my $node = $dom->at( 'footer #app-info' ) ) {
            is $node->text, $app->data->{info}, 'app-info is correct';
        }

        my $prev = $dom->at( '.pager .prev' );
        is $prev->at( 'a' )->attr( 'class' ), 'button disabled';
        is $prev->at( 'a' )->attr( 'href' ), '';

        my $next = $dom->at( '.pager .next' );
        is $next->at( 'a' )->attr( 'class' ), 'button disabled';
        is $next->at( 'a' )->attr( 'href' ), '';
    },

    '/blog/tag/more/index.html' => sub {
        my ( $html, $dom ) = @_;

        cmp_deeply [ $dom->find( 'h1 a' )->map( 'text' )->each ],
            [ 'More Tags' ],
            '"more" page has 1 post title';

        cmp_deeply [ $dom->find( 'h1 a' )->map( attr => 'href' )->each ],
            [ '/blog/2014/06/02/more_tags/', ],
            '"more" page has 1 post url';

        ok !$dom->at( '.author' ), 'no author for this post';

        cmp_deeply [ $dom->find( '.tags a' )->map( attr => 'href' )->each ],
            bag( qw(
                /blog/tag/better/
                /blog/tag/error-message/
                /blog/tag/more/
                /blog/tag/even-more-tags/
            ) ),
            'tag list is available';

        cmp_deeply [ $dom->find( '.feeds a' )->map( attr => 'href' )->each ],
            bag( qw(
                /blog/tag/more.atom
                /blog/tag/more.rss
            ) ),
            'feeds list is available';

        if ( ok my $node = $dom->at( 'footer #app-info' ) ) {
            is $node->text, $app->data->{info}, 'app-info is correct';
        }

        my $prev = $dom->at( '.pager .prev' );
        is $prev->at( 'a' )->attr( 'class' ), 'button disabled';
        is $prev->at( 'a' )->attr( 'href' ), '';

        my $next = $dom->at( '.pager .next' );
        is $next->at( 'a' )->attr( 'class' ), 'button disabled';
        is $next->at( 'a' )->attr( 'href' ), '';
    },

    '/blog/tag/even-more-tags/index.html' => sub {
        my ( $html, $dom ) = @_;

        cmp_deeply [ $dom->find( 'h1 a' )->map( 'text' )->each ],
            [ 'More Tags' ],
            '"even more tags" page has 1 post title';

        cmp_deeply [ $dom->find( 'h1 a' )->map( attr => 'href' )->each ],
            [ '/blog/2014/06/02/more_tags/', ],
            '"even more tags" page has 1 post url';

        ok !$dom->at( '.author' ), 'no author for this post';

        cmp_deeply [ $dom->find( '.tags a' )->map( attr => 'href' )->each ],
            bag( qw(
                /blog/tag/better/
                /blog/tag/error-message/
                /blog/tag/more/
                /blog/tag/even-more-tags/
            ) ),
            'tag list is available';

        cmp_deeply [ $dom->find( '.feeds a' )->map( attr => 'href' )->each ],
            bag( qw(
                /blog/tag/even-more-tags.atom
                /blog/tag/even-more-tags.rss
            ) ),
            'feeds list is available';

        if ( ok my $node = $dom->at( 'footer #app-info' ) ) {
            is $node->text, $app->data->{info}, 'app-info is correct';
        }

        my $prev = $dom->at( '.pager .prev' );
        is $prev->at( 'a' )->attr( 'class' ), 'button disabled';
        is $prev->at( 'a' )->attr( 'href' ), '';

        my $next = $dom->at( '.pager .next' );
        is $next->at( 'a' )->attr( 'class' ), 'button disabled';
        is $next->at( 'a' )->attr( 'href' ), '';
    },

    # Tag feeds
    '/blog/tag/better.atom' => sub {
        my ( $atom, $dom ) = @_;

        is $dom->at( 'feed > id' )->text, 'http://example.com/blog/tag/better/';
        is $dom->at( 'feed > title' )->text, 'Example Site';
        like $dom->at( 'feed > updated' )->text, qr{^\d{4}-\d{2}-\d{2}T\d{2}:\d{2}:\d{2}Z};

        is $dom->at( 'feed > link[rel=self]' )->attr( 'href' ),
            'http://example.com/blog/tag/better.atom';
        is $dom->at( 'feed > link[rel=alternate]' )->attr( 'href' ),
            'http://example.com/blog/tag/better/';

        is $dom->at( 'feed > generator' )->text, 'Statocles';
        is $dom->at( 'feed > generator' )->attr( 'version' ), $Statocles::VERSION;

        cmp_deeply [ $dom->find( 'entry id' )->map( 'text' )->each ],
            [
                'http://example.com/blog/2014/06/02/more_tags/',
                'http://example.com/blog/2014/05/22/(regex)[name].file.html',
            ],
            'atom feed has 2 latest post paths';

        cmp_deeply [ $dom->find( 'entry title' )->map( 'text' )->each ],
            [ 'More Tags', 'Regex violating Post' ],
            'atom feed has 2 latest post titles';

        cmp_deeply [ $dom->find( 'entry author name' )->map( 'text' )->each ],
            [ 'preaction' ],
            'author is correct';

        cmp_deeply [ $dom->find( 'entry content' )->map( attr => 'type' )->each ],
            [ ( 'html' ) x 2 ],
            'content type is correct';
    },

    '/blog/tag/better.rss' => sub {
        my ( $rss, $dom ) = @_;

        is $dom->at( 'channel > title' )->text, 'Example Site';
        is $dom->at( 'channel > link' )->text, 'http://example.com/blog/tag/better/';
        is $dom->at( 'channel > description' )->text, 'Blog feed of Example Site';

        is $dom->at( 'channel > link[rel=self]' )->attr( 'href' ),
            'http://example.com/blog/tag/better.rss';

        is $dom->at( 'channel > generator' )->text, 'Statocles ' . $Statocles::VERSION;

        cmp_deeply [ $dom->find( 'item link' )->map( 'text' )->each ],
            [
                'http://example.com/blog/2014/06/02/more_tags/',
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
            'http://example.com/blog/tag/error-message/';
        is $dom->at( 'feed > title' )->text, 'Example Site';
        like $dom->at( 'feed > updated' )->text,
            qr{^\d{4}-\d{2}-\d{2}T\d{2}:\d{2}:\d{2}Z};

        is $dom->at( 'feed > link[rel=self]' )->attr( 'href' ),
            'http://example.com/blog/tag/error-message.atom';
        is $dom->at( 'feed > link[rel=alternate]' )->attr( 'href' ),
            'http://example.com/blog/tag/error-message/';

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
        is $dom->at( 'channel > link' )->text, 'http://example.com/blog/tag/error-message/';
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
            'http://example.com/blog/tag/more/';
        is $dom->at( 'feed > title' )->text, 'Example Site';
        like $dom->at( 'feed > updated' )->text,
            qr{^\d{4}-\d{2}-\d{2}T\d{2}:\d{2}:\d{2}Z};

        is $dom->at( 'feed > link[rel=self]' )->attr( 'href' ),
            'http://example.com/blog/tag/more.atom';
        is $dom->at( 'feed > link[rel=alternate]' )->attr( 'href' ),
            'http://example.com/blog/tag/more/';

        is $dom->at( 'feed > generator' )->text, 'Statocles';
        is $dom->at( 'feed > generator' )->attr( 'version' ), $Statocles::VERSION;

        cmp_deeply [ $dom->find( 'entry id' )->map( 'text' )->each ],
            [
                'http://example.com/blog/2014/06/02/more_tags/',
            ],
            'atom feed has correct post paths';

        cmp_deeply [ $dom->find( 'entry title' )->map( 'text' )->each ],
            [ 'More Tags' ],
            'atom feed has correct post titles';

        ok !$dom->at( '.author' ), 'no author for this post';

        cmp_deeply [ $dom->find( 'entry content' )->map( attr => 'type' )->each ],
            [ 'html' ],
            'content type is correct';
    },

    '/blog/tag/more.rss' => sub {
        my ( $rss, $dom ) = @_;

        is $dom->at( 'channel > title' )->text, 'Example Site';
        is $dom->at( 'channel > link' )->text, 'http://example.com/blog/tag/more/';
        is $dom->at( 'channel > description' )->text, 'Blog feed of Example Site';

        is $dom->at( 'channel > link[rel=self]' )->attr( 'href' ),
            'http://example.com/blog/tag/more.rss';

        is $dom->at( 'channel > generator' )->text, 'Statocles ' . $Statocles::VERSION;

        cmp_deeply [ $dom->find( 'item link' )->map( 'text' )->each ],
            [
                'http://example.com/blog/2014/06/02/more_tags/',
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
            'http://example.com/blog/tag/even-more-tags/';
        is $dom->at( 'feed > title' )->text, 'Example Site';
        like $dom->at( 'feed > updated' )->text,
            qr{^\d{4}-\d{2}-\d{2}T\d{2}:\d{2}:\d{2}Z};

        is $dom->at( 'feed > link[rel=self]' )->attr( 'href' ),
            'http://example.com/blog/tag/even-more-tags.atom';
        is $dom->at( 'feed > link[rel=alternate]' )->attr( 'href' ),
            'http://example.com/blog/tag/even-more-tags/';

        is $dom->at( 'feed > generator' )->text, 'Statocles';
        is $dom->at( 'feed > generator' )->attr( 'version' ), $Statocles::VERSION;

        cmp_deeply [ $dom->find( 'entry id' )->map( 'text' )->each ],
            [
                'http://example.com/blog/2014/06/02/more_tags/',
            ],
            'atom feed has correct post paths';

        cmp_deeply [ $dom->find( 'entry title' )->map( 'text' )->each ],
            [ 'More Tags' ],
            'atom feed has correct post titles';

        ok !$dom->at( '.author' ), 'no author for this post';

        cmp_deeply [ $dom->find( 'entry content' )->map( attr => 'type' )->each ],
            [ 'html' ],
            'content type is correct';
    },

    '/blog/tag/even-more-tags.rss' => sub {
        my ( $rss, $dom ) = @_;

        is $dom->at( 'channel > title' )->text, 'Example Site';
        is $dom->at( 'channel > link' )->text,
            'http://example.com/blog/tag/even-more-tags/';
        is $dom->at( 'channel > description' )->text, 'Blog feed of Example Site';

        is $dom->at( 'channel > link[rel=self]' )->attr( 'href' ),
            'http://example.com/blog/tag/even-more-tags.rss';

        is $dom->at( 'channel > generator' )->text, 'Statocles ' . $Statocles::VERSION;

        cmp_deeply [ $dom->find( 'item link' )->map( 'text' )->each ],
            [
                'http://example.com/blog/2014/06/02/more_tags/',
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
    '/blog/2014/04/23/slug/index.html' => sub {
        my ( $html, $dom ) = @_;

        is $dom->at( 'header h1' )->text, 'First Post';
        is $dom->at( '.author' )->text, 'preaction';
        is $dom->at( 'aside time' )->attr( 'datetime' ), '2014-04-30', 'date from document';
        ok !scalar $dom->find( 'header .tags a' )->each, 'no tags';

        # alternate, blogs.perl.org, http://blogs.perl.org/preaction/404.html
        is $dom->at( '.alternate a' )->attr( 'href' ),
            'http://blogs.perl.org/preaction/404.html';
        is $dom->at( '.alternate a em' )->text, 'First Post';
        is $dom->at( '.alternate a' )->text, 'on blogs.perl.org.';

        if ( ok my $node = $dom->at( 'footer #app-info' ) ) {
            is $node->text, $app->data->{info}, 'app-info is correct';
        }
    },

    '/blog/2014/04/30/plug/index.html' => sub {
        my ( $html, $dom ) = @_;

        is $dom->at( 'header h1' )->text, 'Second Post';
        is $dom->at( '.author' )->text, 'preaction';
        is $dom->at( 'aside time' )->attr( 'datetime' ), '2014-04-30', 'date from document';

        cmp_deeply [ $dom->find( '.tags a' )->map( 'text' )->each ],
            [ 'better' ];
        cmp_deeply [ $dom->find( '.tags a' )->map( attr => 'href' )->each ],
            [ '/blog/tag/better/' ];

        ok !scalar $dom->find( '.alternate' )->each, 'no alternate';

        if ( ok my $node = $dom->at( 'footer #app-info' ) ) {
            is $node->text, $app->data->{info}, 'app-info is correct';
        }
    },

    '/blog/2014/05/22/(regex)[name].file.html' => sub {
        my ( $html, $dom ) = @_;

        is $dom->at( 'header h1' )->text, 'Regex violating Post';
        is $dom->at( '.author' )->text, 'preaction';
        is $dom->at( 'aside time' )->attr( 'datetime' ), '2014-05-22',
            'post date from location. document has no date';

        cmp_deeply [ $dom->find( '.tags a' )->map( 'text' )->each ],
            bag( 'better', 'error message' );
        cmp_deeply [ $dom->find( '.tags a' )->map( attr => 'href' )->each ],
            bag( qw(
                /blog/tag/better/
                /blog/tag/error-message/
            ) );

        ok !scalar $dom->find( '.alternate' )->each, 'no alternate';

        if ( ok my $node = $dom->at( 'footer #app-info' ) ) {
            is $node->text, $app->data->{info}, 'app-info is correct';
        }
    },

    '/blog/2014/06/02/more_tags/index.html' => sub {
        my ( $html, $dom ) = @_;

        is $dom->at( 'header h1' )->text, 'More Tags';
        ok !$dom->at( '.author' ), 'no author for this page';
        is $dom->at( 'aside time' )->attr( 'datetime' ), '2014-06-02', 'date from path';

        cmp_deeply [ $dom->find( '.tags a' )->map( 'text' )->each ],
            bag( 'more', 'better', 'even more tags' );
        cmp_deeply [ $dom->find( '.tags a' )->map( attr => 'href' )->each ],
            bag( qw(
                /blog/tag/more/
                /blog/tag/better/
                /blog/tag/even-more-tags/
            ) );

        my %links = (
            # TEXT => URL
            "Body Content" => '/does_not_exist',
            "relative" => 'does_not_exist',
            "Broken link with URL encoding" => '/images/with%20spaces.png',
            "Working link with URL encoding" => '/blog/2014/05/22/%28regex%29%5Bname%5D.file.html',
            "Full URLs are not broken" => 'http://example.com',
            "Full URLs without schema are not broken" => '//example.com',
            "Fixed relative URL" => 'docs.html',
            "Test a mailto: link" => 'mailto:user@example.com',
        );
        my @links = $dom->find( 'section a' )->each;
        is scalar @links, scalar keys %links, 'all links found';
        for my $link ( @links ) {
            is $link->attr( 'href' ), $links{ $link->text }, 'link href is correct';
        }

        # alternate, blogs.perl.org, http://blogs.perl.org/preaction/404.html
        is $dom->at( '.alternate a' )->attr( 'href' ),
            'http://blogs.perl.org/preaction/404.html';
        is $dom->at( '.alternate a em' )->text, 'More Tags';
        is $dom->at( '.alternate a' )->text, 'on blogs.perl.org.';

        if ( ok my $node = $dom->at( 'footer #app-info' ) ) {
            is $node->text, $app->data->{info}, 'app-info is correct';
        }
    },

    # Does not show /blog/9999/12/31/forever-is-a-long-time/index.html
    # Does not show /blog/draft/a-draft-post.html

    # Collateral files
    '/blog/2014/04/30/plug/image.jpg' => sub {
        my ( $content ) = @_;

        is $content, $SHARE_DIR->child(qw( app blog 2014 04 30 plug image.jpg ))->slurp;
    },

    # Test that only markdown files get markdowned
    '/blog/2014/06/02/more_tags/image.markdown.jpg' => sub {
        my ( $content ) = @_;

        is $content, $SHARE_DIR->child(qw( app blog 2014 06 02 more_tags image.markdown.jpg ))->slurp;
    },

    # Extra pages
    '/blog/2014/04/30/plug/recipe.html' => sub {
        my ( $html, $dom ) = @_;

        is $dom->at( 'h2' )->text, "Recipe page";
    },

    '/blog/2014/06/02/more_tags/docs.html' => sub {
        my ( $html, $dom ) = @_;

        is $dom->at( 'p' )->text, "This is some documentation. It isn't very good.";
    },
);


test_pages( $site, $app, @page_tests );

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

    test_pages( $site, $app, @page_tests );
    is setlocale( LC_TIME ), 'ru_RU', 'locale is preserved';
    setlocale( LC_TIME, "" );
};

subtest 'blog with no pages is still built' => sub {
    my $app = Statocles::App::Blog->new(
        store => tempdir,
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
    ok $found;
};

done_testing;

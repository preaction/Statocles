
use Test::Lib;
use My::Test;
use Statocles::Site;
use Statocles::Page::ListItem;
use Statocles::Page::Document;
use Statocles::Document;
use Mojo::DOM;
my $site = Statocles::Site->new(
    base_url => 'http://example.com/base',
    deploy => tempdir,
);

my $content = <<'MARKDOWN';
# Page

[Relative link](relative.html)

[Absolute link](/absolute.html)

[Full link](http://example.net)

[Schemaless link](//example.net)

![](image.jpg)

---

![](image2.jpg)

MARKDOWN

my $doc = Statocles::Document->new(
    title => 'Test',
    path => '/path/to/blog/post/index.markdown',
    content => $content,
);

my $inner_page = Statocles::Page::Document->new(
    path => '/path/to/blog/post/index.html',
    document => $doc,
);

subtest 'content rewrite' => sub {

    subtest 'absolute (default)' => sub {
        my $page = Statocles::Page::ListItem->new(
            page => $inner_page,
        );

        subtest 'content' => sub {
            my $dom = Mojo::DOM->new( $page->content );
            ok $dom->at( 'a[href=/path/to/blog/post/relative.html]' ), 'relative link is fixed';
            ok $dom->at( 'a[href=/absolute.html]' ), 'absolute link is ignored';
            ok $dom->at( 'a[href=http://example.net]' ), 'full link is ignored';
            ok $dom->at( 'a[href=//example.net]' ), 'schemaless link is ignored';
            ok $dom->at( 'img[src=/path/to/blog/post/image.jpg]' ), 'relative image is fixed';
            ok $dom->at( 'img[src=/path/to/blog/post/image2.jpg]' ), 'relative image2 is fixed';
        };

        subtest 'sections' => sub {
            my $dom = Mojo::DOM->new( $page->sections(1) );
            ok $dom->at( 'a[href=/path/to/blog/post/relative.html]' ), 'relative link is fixed';
            ok $dom->at( 'a[href=/absolute.html]' ), 'absolute link is ignored';
            ok $dom->at( 'a[href=http://example.net]' ), 'full link is ignored';
            ok $dom->at( 'a[href=//example.net]' ), 'schemaless link is ignored';
            ok $dom->at( 'img[src=/path/to/blog/post/image.jpg]' ), 'relative image is fixed';
        };
    };

    subtest 'full (flag)' => sub {
        my $page = Statocles::Page::ListItem->new(
            page => $inner_page,
            rewrite_mode => 'full',
        );

        subtest 'content' => sub {
            my $dom = Mojo::DOM->new( $page->content );
            ok $dom->at( 'a[href=http://example.com/base/path/to/blog/post/relative.html]' ), 'relative link is fixed';
            ok $dom->at( 'a[href=http://example.com/base/absolute.html]' ), 'absolute link is fixed';
            ok $dom->at( 'a[href=http://example.net]' ), 'full link is ignored';
            ok $dom->at( 'a[href=//example.net]' ), 'schemaless link is ignored';
            ok $dom->at( 'img[src=http://example.com/base/path/to/blog/post/image.jpg]' ), 'relative image is fixed';
            ok $dom->at( 'img[src=http://example.com/base/path/to/blog/post/image2.jpg]' ), 'relative image2 is fixed';
        };

        subtest 'sections' => sub {
            my $dom = Mojo::DOM->new( $page->sections(1) );
            ok $dom->at( 'a[href=http://example.com/base/path/to/blog/post/relative.html]' ), 'relative link is fixed';
            ok $dom->at( 'a[href=http://example.com/base/absolute.html]' ), 'absolute link is fixed';
            ok $dom->at( 'a[href=http://example.net]' ), 'full link is ignored';
            ok $dom->at( 'a[href=//example.net]' ), 'schemaless link is ignored';
            ok $dom->at( 'img[src=http://example.com/base/path/to/blog/post/image.jpg]' ), 'relative image is fixed';
        };
    };
};

subtest 'method proxy' => sub {
    my $page = Statocles::Page::ListItem->new(
        page => $inner_page,
    );

    is $page->basename, $inner_page->basename, 'basename is proxyed';
    is $page->dirname, $inner_page->dirname, 'dirname is proxyed';
    is $page->title, $inner_page->title, 'title is proxied';

    throws_ok { $page->BADMETHOD }
        qr{\QListItem page (/path/to/blog/post/index.html Statocles::Page::Document) has no method "BADMETHOD"};
    lives_ok { $page->DESTROY };
};

done_testing;

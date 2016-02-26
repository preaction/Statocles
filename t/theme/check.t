
# Check the syntax of all the built-in theme bundles
use Test::Lib;
use My::Test;
$Statocles::VERSION = '0.000001';
use Statocles::Document;
use Statocles::Page::List;
use Statocles::Page::Document;
use Statocles::App::Blog;
use Statocles::Site;
use Statocles::Theme;
use Statocles::Link;
use Mojo::DOM;
use Mojo::Util qw( xml_escape );

my $THEME_DIR = path( __DIR__, '..', '..', 'share', 'theme' );

my %document_common = (
    links => {
        stylesheet => [
            {
                href => '/theme/css/special.css',
            },
        ],
        script => [
            {
                href => '/theme/js/special.js',
            },
        ],
    },
);

my %document = (
    normal => Statocles::Document->new(
        path => 'DUMMY',
        title => 'Page Title',
        author => 'preaction',
        content => 'Content One',
        date => '2015-01-01 00:00:00',
        %document_common,
    ),
    escaped => Statocles::Document->new(
        path => '/$escape/@this/(correctly)/index.html',
        title => '<ESCAPE>',
        content => '<b>Must not be escaped</b>',
        date => '2015-01-02 00:00:00',
        %document_common,
    ),
);

my $blog = Statocles::App::Blog->new(
    url_root => '/blog',
    store => '.',
    tag_text => {
        foo => <<ENDMARKDOWN,
# Foo!

Bar, baz, and fuzz!
ENDMARKDOWN
    },
);

my $site = Statocles::Site->new(
    base_url => 'http://example.com',
    build_store => '.',
    deploy => '.',
    title => '<Site Title>',
    theme => '.',
    apps => {
        blog => $blog,
    },
    images => {
        icon => {
           src => '/favicon.ico',
        },
    },
    links => {
        stylesheet => [
            {
                href => '/theme/css/site-style.css',
            },
        ],
        script => [
            {
                href => '/theme/js/site-script.js',
            },
        ],
    },
);

my %page = (
    normal => Statocles::Page::Document->new(
        path => 'document.html',
        document => $document{normal},
        tags => [
            Statocles::Link->new(
                href => '/blog/tag/foo',
                text => 'foo',
            ),
            Statocles::Link->new(
                href => '/blog/tag/bar',
                text => 'bar',
            ),
        ],
    ),
    escaped => Statocles::Page::Document->new(
        path => '/$escape/@this/(correctly)/index.html',
        document => $document{escaped},
    ),

);

$page{ list } = Statocles::Page::List->new(
    app => $blog,
    path => 'list.html',
    pages => [ $page{ normal }, $page{ escaped } ],
    next => 'page-0.html',
    prev => 'page-1.html',
    data => {
        tag_text => $blog->tag_text->{ foo },
    },
);

$page{ feed } = Statocles::Page::List->new(
    app => $blog,
    path => 'feed.rss',
    pages => $page{ list }->pages,
    links => {
        alternate => [
            Statocles::Link->new(
                href => $page{list}->path,
                title => 'index',
            ),
        ],
    },
);

my %common_vars = (
    site => $site,
    content => 'Fake content',
    app => $blog,
);

my %app_vars = (
    blog => {
        'index.html.ep' => {
            %common_vars,
            self => $page{ list },
            pages => [ $page{ normal }, $page{ escaped } ],
        },
        'index.rss.ep' => {
            %common_vars,
            self => $page{ feed },
            pages => [ $page{ normal }, $page{ escaped } ],
        },
        'index.atom.ep' => {
            %common_vars,
            self => $page{ feed },
            pages => [ $page{ normal }, $page{ escaped } ],
        },
        'post.html.ep' => [
            {
                %common_vars,
                self => $page{ normal },
                doc => $document{ normal },
            },
            {
                %common_vars,
                self => $page{ escaped },
                doc => $document{ escaped },
            },
        ],
    },

    perldoc => {
        'pod.html.ep' => {
            %common_vars,
            self => Statocles::Page::Plain->new(
                path => '/path',
                content => 'Fake content',
                data => {
                    source_path => '/source.html',
                },
            ),
            content => 'Fake content',
        },
        'source.html.ep' => {
            %common_vars,
            self => Statocles::Page::Plain->new(
                path => '/path',
                content => 'Fake content',
                data => {
                    doc_path => '/source.html',
                },
            ),
            content => 'Fake content',
        },
    },

    site => {
        'layout.html.ep' => [
            {
                %common_vars,
                self => $page{ normal },
                app => $blog,
            },
            {
                %common_vars,
                self => $page{ escaped },
                doc => $document{ escaped },
            },
        ],
        'sitemap.xml.ep' => {
            site => $site,
            pages => [ $page{ list }, $page{ normal }, $page{ escaped } ],
        },
        'robots.txt.ep' => {
            site => $site,
        },
    },
);

# These are individual template tests to ensure basic levels of app support
# in the default themes
my %content_tests = (
    'site/layout.html.ep' => sub {
        my ( $content, %args ) = @_;
        my $dom = Mojo::DOM->new( $content );
        my $elem;

        subtest 'page title and site title' => sub {
            if ( ok $elem = $dom->at( 'title' ), 'title element exists' ) {
                like $elem->text, qr{@{[quotemeta $args{self}->title]}}, 'title has document title';
                like $elem->text, qr{@{[quotemeta $site->title]}}, 'title has site title';
            }
        };

        subtest 'all themes must have meta generator' => sub {
            if ( ok $elem = $dom->at( 'meta[name=generator]' ), 'meta generator exists' ) {
                is $elem->attr( 'content' ), "Statocles $Statocles::VERSION",
                    'generator has name and version';
            }
        };

        subtest 'site stylesheet and script links get added' => sub {
            if ( ok $elem = $dom->at( 'link[href=/theme/css/site-style.css]', 'site stylesheet exists' ) ) {
                is $elem->attr( 'rel' ), 'stylesheet';
                is $elem->attr( 'type' ), 'text/css';
            }
            if ( ok $elem = $dom->at( 'script[src=/theme/js/site-script.js]', 'site script exists' ) ) {
                ok !$elem->text, 'no text inside';
            }
        };

        subtest 'document stylesheet links get added in the layout' => sub {
            if ( ok $elem = $dom->at( 'link[href=/theme/css/special.css]', 'document stylesheet exists' ) ) {
                is $elem->attr( 'rel' ), 'stylesheet';
                is $elem->attr( 'type' ), 'text/css';
            }
        };

        subtest 'document script links get added in the layout' => sub {
            if ( ok $elem = $dom->at( 'script[src=/theme/js/special.js]', 'document script exists' ) ) {
                ok !$elem->text, 'no text inside';
            }
        };

        subtest 'shortcut icon' => sub {
            if ( ok $elem = $dom->at( 'link[rel="shortcut icon"]', 'shortcut icon link exists' ) ) {
                is $elem->attr( 'href' ), '/favicon.ico';
            }
        };

    },

    'site/sitemap.xml.ep' => sub {
        my ( $content, %args ) = @_;
        my $xml = Mojo::DOM->new( $content );
        my @got_loc = $xml->find( 'loc' )->map( 'text' )->each;
        cmp_deeply \@got_loc, array_each( re( qr{^http://example[.]com/} ) ), 'all pages are full urls';
    },

    'blog/index.rss.ep' => sub {
        my ( $content, %args ) = @_;
        my $xml = Mojo::DOM->new( $content );
        my @posts = $xml->find( 'item description' )->map( sub { Mojo::DOM->new( $_[0]->child_nodes->first->content ) } )->each;

        subtest 'all links must be full URLs' => sub {
            for my $post ( @posts ) {
                my @links = $post->find( 'a[href]' )->each;
                ok scalar @links, 'some links were found';
                for my $link ( @links ) {
                    like $link->attr( 'href' ), qr{^(?:https?:|mailto:|//)}, 'full URL';
                }
            }
        };

        subtest 'item title' => sub {
            my @titles = $xml->find( 'item title' )->each;
            is scalar @titles, scalar @{ $args{pages} }, 'right number of item titles found';
            for my $i ( 0..$#titles ) {
                my $elem = $titles[ $i ];
                like $elem->text, qr{@{[quotemeta $args{pages}[$i]->title]}}, 'title has document title';
                unlike $elem->text, qr{@{[quotemeta $site->title]}}, 'title must not have site title';
            }
        };
    },

    'blog/index.atom.ep' => sub {
        my ( $content, %args ) = @_;
        my $xml = Mojo::DOM->new( $content );

        subtest 'feed updated' => sub {
            if ( ok my $elem = $xml->at( 'feed > updated' ), 'feed has updated element' ) {
                like $elem->text, qr{^\d{4}-\d{2}-\d{2}T\d{2}:\d{2}:\d{2}Z$}, 'date in iso8601 format';
                is $elem->text, '2015-01-02T00:00:00Z', 'date is latest of all pages';
            }
        };

        subtest 'entry title' => sub {
            my @titles = $xml->find( 'entry title' )->each;
            is scalar @titles, scalar @{ $args{pages} }, 'right number of entry titles found';
            for my $i ( 0..$#titles ) {
                my $elem = $titles[ $i ];
                like $elem->text, qr{@{[quotemeta $args{pages}[$i]->title]}}, 'title has document title';
                unlike $elem->text, qr{@{[quotemeta $site->title]}}, 'title must not have site title';
            }
        };
    },

    'blog/index.html.ep' => sub {
        my ( $content, %args ) = @_;
        my $dom = Mojo::DOM->new( $content );

        subtest 'tag text exists and is processed as Markdown' => sub {
            if ( ok my $h1 = $dom->at( 'main > h1' ), 'tag text h1 exists' ) {
                is $h1->text, 'Foo!', 'h1 text is correct';
            }
            if ( ok my $p = $dom->at( 'main > p' ), 'tag text p exists' ) {
                is $p->text, 'Bar, baz, and fuzz!', 'p text is correct';
            }
        };

        subtest 'post titles' => sub {
            # Article titles should be isolated from the body by using
            # the <header> tag
            my @post_titles = $dom->find( 'article header h1' )->each;
            is scalar @post_titles, scalar @{ $args{pages} }, 'right number of post titles found (article header h1)';
            for my $i ( 0..$#post_titles ) {
                ok my $elem = $post_titles[ $i ]->at( 'a' ), "article titles must be a link to the article";
                next unless $elem;
                like $elem->text, qr{@{[quotemeta $args{pages}[$i]->title]}}, 'title has document title';
            }
        };
    },

    'blog/post.html.ep' => sub {
        my ( $content, %args ) = @_;
        my $dom = Mojo::DOM->new( $content );

        subtest 'post title' => sub {
            # Article title should be isolated from the body by using
            # the <header> tag
            ok my $elem = $dom->at( 'main header h1' ), 'post title found (main header h1)';
            return unless $elem;
            like $elem->text, qr{@{[quotemeta $args{self}->title]}}, 'title has document title';
        };
    },
);


my @theme_dirs = $THEME_DIR->children;
for my $theme_dir ( @theme_dirs ) {
    my $theme = Statocles::Theme->new(
        store => $theme_dir,
    );

    subtest $theme_dir->basename => sub {
        my $iter = $theme_dir->iterator({ recurse => 1 });
        while ( my $path = $iter->() ) {
            next unless $path->is_file;
            next unless $path->basename =~ /[.]ep$/;
            next unless $path->stat->size > 0;

            my $tmpl_path = $path->relative( $theme_dir );
            $tmpl_path =~ s/[.]ep$//;
            my $tmpl = $theme->template( $tmpl_path );

            my $name = $path->basename;
            my $app = $path->parent->basename;

            my $arg_sets = $app_vars{ $app }{ $name };
            if ( ref $arg_sets ne 'ARRAY' ) {
                $arg_sets = [ $arg_sets ];
            }

            for my $i ( 0..$#$arg_sets ) {
                my $arg_set = $arg_sets->[ $i ];
                my %args = %{ $arg_set };
                my $content;
                lives_ok {
                    $content = $tmpl->render( %args );
                } sprintf "%s - %s (%d)", $app, $name, $i;

                my $rel_path = $path->relative( $theme_dir );
                if ( my $test = $content_tests{ $rel_path } ) {
                    subtest "content test for $rel_path ($i)"
                        => $test, $content, %args;
                }
            }
        }
    };
}

done_testing;

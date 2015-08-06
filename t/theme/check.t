
# Check the syntax of all the built-in theme bundles

use Statocles::Base 'Test';
$Statocles::VERSION = '0.000001';
use Statocles::Document;
use Statocles::Page::List;
use Statocles::Page::Document;
use Statocles::App::Blog;
use Statocles::Site;
use Statocles::Theme;
use Statocles::Link;
use Mojo::DOM;

my $THEME_DIR = path( __DIR__, '..', '..', 'share', 'theme' );

my @documents = (
    Statocles::Document->new(
        path => 'DUMMY',
        title => 'Title One',
        author => 'preaction',
        content => 'Content One',
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
    ),
    Statocles::Document->new(
        path => 'DUMMY',
        title => 'Title Two',
        content => 'Content Two',
    ),
);

my $blog = Statocles::App::Blog->new(
    url_root => '/blog',
    store => '.',
);

my $site = Statocles::Site->new(
    base_url => 'http://example.com',
    build_store => '.',
    deploy => '.',
    title => 'Test Title',
    theme => '.',
    apps => {
        blog => $blog,
    },
);

my %page = (
    document => Statocles::Page::Document->new(
        path => 'document.html',
        document => $documents[0],
        date => Time::Piece->new,
    ),
);

$page{ list } = Statocles::Page::List->new(
    app => $blog,
    path => 'list.html',
    pages => [ $page{ document } ],
    next => 'page-0.html',
    prev => 'page-1.html',
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
            pages => [ $page{ document } ],
        },
        'index.rss.ep' => {
            %common_vars,
            self => $page{ feed },
            pages => [ $page{ document } ],
        },
        'index.atom.ep' => {
            %common_vars,
            self => $page{ feed },
            pages => [ $page{ document } ],
        },
        'post.html.ep' => {
            %common_vars,
            self => $page{ document },
            doc => $documents[0],
        },
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
        'layout.html.ep' => {
            %common_vars,
            self => $page{ document },
            app => $blog,
        },
        'sitemap.xml.ep' => {
            site => $site,
            pages => [ $page{ list }, $page{ document } ],
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
        my ( $content ) = @_;
        my $dom = Mojo::DOM->new( $content );
        my $elem;

        subtest 'page title and site title' => sub {
            if ( ok $elem = $dom->at( 'title' ), 'title element exists' ) {
                is $elem->text, "Title One - Test Title",
                    'title has document title and site title';
            }
        };

        subtest 'all themes must have meta generator' => sub {
            if ( ok $elem = $dom->at( 'meta[name=generator]' ), 'meta generator exists' ) {
                is $elem->attr( 'content' ), "Statocles $Statocles::VERSION",
                    'generator has name and version';
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

    },
);


my @theme_dirs = $THEME_DIR->children;
for my $theme_dir ( @theme_dirs ) {
    subtest $theme_dir->basename => sub {
        my $iter = $theme_dir->iterator({ recurse => 1 });
        while ( my $path = $iter->() ) {
            next unless $path->is_file;
            next unless $path->basename =~ /[.]ep$/;
            next unless $path->stat->size > 0;

            my $tmpl = Statocles::Template->new(
                path => $path,
                include_stores => $theme_dir,
            );
            my $name = $path->basename;
            my $app = $path->parent->basename;
            my %args = %{ $app_vars{ $app }{ $name } };
            my $content;
            lives_ok {
                $content = $tmpl->render( %args );
            } join " - ", $app, $name;

            my $rel_path = $path->relative( $theme_dir );
            if ( my $test = $content_tests{ $rel_path } ) {
                subtest "content test for $rel_path" => $test, $content;
            }
        }
    };
}

done_testing;

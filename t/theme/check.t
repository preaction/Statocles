
# Check the syntax of all the built-in theme bundles

use Statocles::Base 'Test';
$Statocles::VERSION = '0.000001';
use Statocles::Document;
use Statocles::Page::List;
use Statocles::Page::Document;
use Statocles::Page::Feed;
use Statocles::App::Blog;
use Statocles::Site;
use Statocles::Theme;

my $THEME_DIR = path( __DIR__, '..', '..', 'share', 'theme' );

my @documents = (
    Statocles::Document->new(
        path => 'DUMMY',
        title => 'Title One',
        author => 'preaction',
        content => 'Content One',
    ),
    Statocles::Document->new(
        path => 'DUMMY',
        title => 'Title Two',
        author => 'preaction',
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
    deploy_store => '.',
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
        published => Time::Piece->new,
    ),
);

$page{ list } = Statocles::Page::List->new(
    app => $blog,
    path => 'list.html',
    pages => [ $page{ document } ],
    next => 'page-0.html',
    prev => 'page-1.html',
);

$page{ feed } = Statocles::Page::Feed->new(
    app => $blog,
    path => 'feed.rss',
    page => $page{ list },
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
    },
);

my @theme_dirs = $THEME_DIR->children;
for my $theme_dir ( @theme_dirs ) {
    subtest $theme_dir->basename => sub {
        my $iter = $theme_dir->iterator({ recurse => 1 });
        while ( my $path = $iter->() ) {
            next unless $path->is_file;
            next unless $path->basename =~ /[.]ep$/;
            my $tmpl = Statocles::Template->new(
                path => $path,
                store => $theme_dir,
            );
            my $name = $path->basename;
            my $app = $path->parent->basename;
            my %args = %{ $app_vars{ $app }{ $name } };
            lives_ok {
                $tmpl->render( %args );
            } join " - ", $app, $name;
        }
    };
}

done_testing;

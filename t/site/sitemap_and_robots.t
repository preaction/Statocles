use Test::Lib;
use My::Test;
use Mojo::DOM;
use Statocles::Site;
use TestDeploy;
use TestApp;
use List::Util qw( first );
my $SHARE_DIR = path( __DIR__, '..', 'share' );

my $site = Statocles::Site->new(
    base_url => 'http://example.com/',
    apps => {
        base => TestApp->new(
            url_root => '/',
            pages => [
                {
                    class => 'Statocles::Page::Plain',
                    path => '/index.html',
                    content => 'Index',
                    date => '2018-01-01',
                },
                {
                    class => 'Statocles::Page::File',
                    path => '/static.txt',
                    file_path => $SHARE_DIR->child( qw( app basic static.txt ) ),
                    date => '2018-01-03',
                },
            ],
        ),
    },
    deploy => TestDeploy->new,
);

my $today = DateTime::Moonpig->now( time_zone => 'local' )->strftime( '%Y-%m-%d' );
my $to_href = sub {
    my $lastmod = $_->at('lastmod');
    return {
        loc => $_->at('loc')->text,
        changefreq => $_->at('changefreq')->text,
        priority => $_->at('priority')->text,
        ( $lastmod ? ( lastmod => $lastmod->text ) : () ),
    };
};

# Must be sorted to prevent spurous deploy commits
my @expect = sort { $a->{loc} cmp $b->{loc} }
    (
        {
            loc => 'http://example.com/',
            changefreq => 'weekly',
            priority => '0.5',
            lastmod => '2018-01-01',
        },
    );

my @pages = $site->pages;
my $robots = first { $_->path eq '/robots.txt' } @pages;
my $sitemap = first { $_->path eq '/sitemap.xml' } @pages;

my $dom = Mojo::DOM->new( $sitemap->content );
if ( ok my $elem = $dom->at('urlset'), 'urlset exists' ) {;
    my @urls = $dom->at('urlset')->children->map( $to_href )->each;
    cmp_deeply \@urls, \@expect or diag explain \@urls, \@expect;
}

cmp_deeply
    [ grep { /\S/ } split qr{\n}, $robots->content ],
    [
        "Sitemap: http://example.com/sitemap.xml",
        "User-Agent: *",
        "Disallow:",
    ] or diag explain $robots->content;

done_testing;


use Test::Lib;
use My::Test;
use TestApp;
use TestDeploy;
use Statocles::Site;
use Statocles::Command::deploy;
my $SHARE_DIR = path( __DIR__, '..', 'share' );

my $app = TestApp->new(
    url_root => '/',
    pages => [
        {
            class => 'Statocles::Page::Plain',
            path => '/index.html',
            content => '<a href="/static.txt">Foo</a>',
        },
        {
            class => 'Statocles::Page::File',
            path => '/static.txt',
            file_path => $SHARE_DIR->child( qw( app basic static.txt ) ),
        },
    ],
);

subtest 'deploy site' => sub {
    my $site = Statocles::Site->new(
        apps => {
            base => $app
        },
        deploy => TestDeploy->new,
    );

    my $cmd = Statocles::Command::deploy->new( site => $site );
    $cmd->run( '--date', '2018-01-01', '--message', 'New site', '--clean' );

    is_deeply { @{ $site->app( 'base' )->last_pages_args } },
        { date => '2018-01-01', message => 'New site', clean => 1, base_url => undef },
        'app pages() method options correct';
    my ( $pages, $options ) = @{ $site->deploy->last_deploy_args };
    is_deeply [ sort grep { !m{^/theme/} } map { $_->path } @$pages ],
        [qw(
            /index.html /robots.txt /sitemap.xml /static.txt
        )],
        'deploy deploy() method page paths correct';
    is_deeply $options,
        { date => '2018-01-01', message => 'New site', clean => 1 },
        'deploy deploy() method options correct';
};

subtest 'deploy site with deploy base_url' => sub {
    my $site = Statocles::Site->new(
        base_url => '/site_base',
        apps => {
            base => $app
        },
        deploy => TestDeploy->new( base_url => '/deploy_base' ),
    );

    my $cmd = Statocles::Command::deploy->new( site => $site );
    $cmd->run;

    is_deeply { @{ $site->app( 'base' )->last_pages_args } },
        { base_url => '/deploy_base' },
        'app pages() method options correct';
    my ( $pages, $options ) = @{ $site->deploy->last_deploy_args };
    is_deeply [ sort grep { !m{^/theme/} } map { $_->path } @$pages ],
        [qw(
            /index.html /robots.txt /sitemap.xml /static.txt
        )],
        'deploy deploy() method page paths correct';
    is_deeply $options, { },
        'deploy deploy() method options correct';

    my ( $base_page ) = grep { $_->path eq '/index.html' } @$pages;
    is $base_page->dom, qq{<a href="/deploy_base/static.txt">Foo</a>\n\n}, 'HTML link is rewritten';
};

done_testing;

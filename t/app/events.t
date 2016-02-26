
use Test::Lib;
use My::Test;
my $SHARE_DIR = path( __DIR__, '..', 'share' );
my $site = build_test_site(
    theme => $SHARE_DIR->child( 'theme' ),
);
use TestApp;

subtest build => sub {
    my @pages = (
        Statocles::Page::Plain->new(
            path => '/index.html',
            content => 'index',
        ),
    );

    my $app = TestApp->new(
        url_root => '/',
        site => $site,
        pages => \@pages,
    );
    $app->on( build => sub {
        my ( $event ) = @_;
        isa_ok $event, 'Statocles::Event::Pages';
        is scalar @{ $event->pages }, scalar @pages, 'got right number of pages';
        cmp_deeply $event->pages, \@pages;

        # Add a new page in the plugin
        push @{ $event->pages }, Statocles::Page::Plain->new(
            path => '/plugin.html',
            content => 'added by plugin',
        );
    } );

    my @got_pages = $app->pages;
    is scalar @got_pages, scalar @pages + 1, 'got another page from plugin';
    is $got_pages[-1]->path, '/plugin.html', 'plugin page exists';
};

done_testing;


use Test::Lib;
use My::Test;
use TestDeploy;
use Statocles::Site;
my $SHARE_DIR = path( __DIR__, '..', 'share' );

my $site = Statocles::Site->new(
    base_url => 'http://example.com',
    deploy => TestDeploy->new,
    nav => {
        main => [
            {
                title => 'Blog',
                href => '/index.html',
            },
            {
                title => 'About Us',
                href => '/about.html',
                text => 'About',
            },
        ],
    },
);

subtest 'nav( NAME ) method' => sub {
    my @links = $site->nav( 'main' );
    cmp_deeply \@links, [
        methods(
            title => 'Blog',
            href => '/index.html',
            text => 'Blog',
        ),
        methods(
            title => 'About Us',
            href => '/about.html',
            text => 'About',
        ),
    ];

    cmp_deeply [ $site->nav( 'MISSING' ) ], [], 'missing nav returns empty list';
};

done_testing;

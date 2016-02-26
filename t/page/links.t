
use Test::Lib;
use My::Test;
use Statocles::Site;
use Statocles::Link;
my $site = Statocles::Site->new( deploy => tempdir );

{
    package TestPage;
    use Statocles::Base 'Class';
    with 'Statocles::Page';
}

subtest 'links' => sub {

    my $page = TestPage->new(
        path => '/index.rss',
        links => {
            alternate => [
                {
                    text => 'Main',
                    href => '/index.html',
                    type => 'text/html',
                },
                {
                    text => 'Atom',
                    href => '/index.atom',
                    type => 'application/atom+xml',
                },
            ],
        },
    );

    subtest 'list' => sub {
        cmp_deeply [ $page->links( 'alternate' ) ],
            [
                Statocles::Link->new(
                    text => 'Main',
                    href => '/index.html',
                    type => 'text/html',
                ),
                Statocles::Link->new(
                    text => 'Atom',
                    href => '/index.atom',
                    type => 'application/atom+xml',
                ),
            ];
    };

    subtest 'scalar' => sub {
        cmp_deeply
            scalar $page->links( 'alternate' ),
            Statocles::Link->new(
                text => 'Main',
                href => '/index.html',
                type => 'text/html',
            );
    };

};

subtest 'add links' => sub {

    subtest 'append to existing' => sub {
        my $existing_link = Statocles::Link->new(
            text => 'Atom',
            href => '/index.atom',
            type => 'application/atom+xml',
        );

        subtest 'plain string' => sub {
            my $page = TestPage->new(
                path => '/index.rss',
                links => { alternate => [ $existing_link ] },
            );
            $page->links( alternate => "http://example.com", "http://example.net" );
            cmp_deeply
                [ $page->links( 'alternate' ) ],
                [
                    $existing_link,
                    Statocles::Link->new( href => 'http://example.com' ),
                    Statocles::Link->new( href => 'http://example.net' ),
                ],
                'URL is coerced into Link object and appended';
        };

        subtest 'hashref' => sub {
            my $page = TestPage->new(
                path => '/index.rss',
                links => { alternate => [ $existing_link ] },
            );
            $page->links( alternate => { type => 'text/html', href => "http://example.com" } );
            cmp_deeply
                [ $page->links( 'alternate' ) ],
                [
                    $existing_link,
                    Statocles::Link->new( type => 'text/html', href => 'http://example.com' ),
                ],
                'Hashref is coerced into Link object and appended';
        };

        subtest 'link object' => sub {
            my $page = TestPage->new(
                path => '/index.rss',
                links => { alternate => [ $existing_link ] },
            );
            $page->links(
                alternate => Statocles::Link->new(
                    type => 'text/html',
                    href => "http://example.com",
                )
            );
            cmp_deeply
                [ $page->links( 'alternate' ) ],
                [
                    $existing_link,
                    Statocles::Link->new( type => 'text/html', href => 'http://example.com' ),
                ],
                'Link object is appended';
        };
    };

    subtest 'add new key' => sub {
        subtest 'plain string' => sub {
            my $page = TestPage->new(
                path => '/index.rss',
            );
            $page->links( alternate => "http://example.com" );
            cmp_deeply
                [ $page->links( 'alternate' ) ],
                [
                    Statocles::Link->new( href => 'http://example.com' ),
                ],
                'URL is coerced into Link object and appended';
        };

        subtest 'hashref' => sub {
            my $page = TestPage->new(
                path => '/index.rss',
            );
            $page->links( alternate => { type => 'text/html', href => "http://example.com" } );
            cmp_deeply
                [ $page->links( 'alternate' ) ],
                [
                    Statocles::Link->new( type => 'text/html', href => 'http://example.com' ),
                ],
                'Hashref is coerced into Link object and appended';
        };

        subtest 'link object' => sub {
            my $page = TestPage->new(
                path => '/index.rss',
            );
            $page->links(
                alternate => Statocles::Link->new(
                    type => 'text/html',
                    href => "http://example.com",
                )
            );
            cmp_deeply
                [ $page->links( 'alternate' ) ],
                [
                    Statocles::Link->new( type => 'text/html', href => 'http://example.com' ),
                ],
                'Link object is appended';
        };
    };
};

subtest 'links should be unique' => sub {
    my $page = TestPage->new(
        path => '/index.rss',
        links => {
            alternate => [
                Statocles::Link->new(
                    text => 'Main',
                    href => '/index.html',
                    type => 'text/html',
                ),
                Statocles::Link->new(
                    text => 'Atom',
                    href => '/index.atom',
                    type => 'application/atom+xml',
                ),
                Statocles::Link->new(
                    text => 'Atom',
                    href => '/index.atom',
                    type => 'application/atom+xml',
                ),
            ],
        },
    );

    cmp_deeply [ $page->links( 'alternate' ) ],
        [
            Statocles::Link->new(
                text => 'Main',
                href => '/index.html',
                type => 'text/html',
            ),
            Statocles::Link->new(
                text => 'Atom',
                href => '/index.atom',
                type => 'application/atom+xml',
            ),
        ],
        'links must be filtered for uniqueness based on href';
};

done_testing;

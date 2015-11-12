
use Statocles::Base 'Test';
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

done_testing;

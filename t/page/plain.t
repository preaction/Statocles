
use Statocles::Base 'Test';
my $SHARE_DIR = path( __DIR__ )->parent->child( 'share' );

use Statocles::Page::Plain;
my $site = Statocles::Site->new( deploy => tempdir );

subtest 'constructor' => sub {
    test_constructor(
        'Statocles::Page::Plain',
        required => {
            path => '/index.html',
            content => 'some test content',
        },
        default => {
            search_change_frequency => 'weekly',
            search_priority => 0.5,
            date => sub {
                isa_ok $_, 'Time::Piece';
            },
        },
    );
};

subtest 'render' => sub {
    my $page = Statocles::Page::Plain->new(
        path => '/path/to/page.html',
        content => 'some test content',
        layout => "LAYOUT\n<%= \$content %>",
        template => "TEMPLATE\n<%= \$content %>",
    );

    eq_or_diff $page->render, "LAYOUT\nTEMPLATE\nsome test content\n\n";
};

done_testing;

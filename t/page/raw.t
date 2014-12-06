
use Statocles::Test;
my $SHARE_DIR = path( __DIR__ )->parent->child( 'share' );

use Statocles::Page::Raw;

subtest 'constructor errors' => sub {
    dies_ok {
        Statocles::Page::Raw->new(
            path => '/allowed.html',
        )
    } 'content is required';
};

subtest 'attribute defaults' => sub {
    my $page = Statocles::Page::Raw->new(
        path => '/path/to/page.html',
        content => 'some test content',
    );

    subtest 'search_change_frequency' => sub {
        is $page->search_change_frequency, 'weekly';
    };

    subtest 'search_priority' => sub {
        is $page->search_priority, 0.5;
    };
};

subtest 'render' => sub {
    my $page = Statocles::Page::Raw->new(
        path => '/path/to/page.html',
        content => 'some test content',
        layout => "LAYOUT\n<%= \$content %>",
        template => "TEMPLATE\n<%= \$content %>",
    );

    eq_or_diff $page->render, "LAYOUT\nTEMPLATE\nsome test content\n\n";
};

done_testing;

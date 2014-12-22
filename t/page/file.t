
use Statocles::Base 'Test';
my $SHARE_DIR = path( __DIR__ )->parent->child( 'share' );

use Statocles::Page::File;

subtest 'constructor' => sub {
    open my $fh, '<', \'string literal';

    test_constructor(
        'Statocles::Page::File',
        required => {
            path => '/index.html',
            fh => $fh,
        },
        default => {
            search_change_frequency => 'weekly',
            search_priority => 0.5,
            last_modified => sub {
                isa_ok $_, 'Time::Piece';
            },
        },
    );
};

subtest 'render' => sub {
    open my $expect_fh, '<', \'string literal';

    my $page = Statocles::Page::File->new(
        path => '/path/to/page.html',
        fh => $expect_fh,
    );

    my $got_fh = $page->render;
    is ref $got_fh, 'GLOB', 'got a filehandle';

    my $got_content = do { local $/; <$got_fh> };
    is $got_content, 'string literal';
};

done_testing;

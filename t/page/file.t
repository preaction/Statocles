use Test::Lib;
use My::Test;
use Statocles::Site;
my $SHARE_DIR = path( __DIR__ )->parent->child( 'share' );

use Statocles::Page::File;
my $site = Statocles::Site->new( deploy => tempdir );

subtest 'constructor' => sub {
    test_constructor(
        'Statocles::Page::File',
        required => {
            path => '/index.html',
        },
        default => {
            search_change_frequency => 'weekly',
            search_priority => 0.5,
            date => sub {
                isa_ok $_, 'DateTime::Moonpig';
            },
        },
    );
};

subtest 'file path' => sub {
    my $page = Statocles::Page::File->new(
        path => '/path/to/page.html',
        file_path => $SHARE_DIR->child( qw( store files text.txt ) ),
    );

    my $got_path = $page->render;
    isa_ok $got_path, 'Path::Tiny', 'got a Path::Tiny object';
    is $got_path, $SHARE_DIR->child( qw( store files text.txt ) );
};

subtest 'images' => sub {
    my $page = Statocles::Page::File->new(
        path => '/path/to/image.png',
        file_path => $SHARE_DIR->child( qw( store files image.png ) ),
    );

    my $got_path = $page->render;
    isa_ok $got_path, 'Path::Tiny', 'got a Path::Tiny object';
    is $got_path, $SHARE_DIR->child( qw( store files image.png ) );
};


subtest 'fh' => sub {
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

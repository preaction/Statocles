
use Test::Lib;
use My::Test;
my $SHARE_DIR = path( __DIR__, '..', 'share' );

subtest 'url method' => sub {
    subtest 'domain only' => sub {
        my $site = build_test_site(
            base_url => 'http://example.com/',
        );

        is $site->url( '/blog/2014/01/01/a-page.html' ),
           'http://example.com/blog/2014/01/01/a-page.html';
        subtest 'index.html is removed' => sub {
            is $site->url( '/index.html' ),
               'http://example.com/';
        };
    };

    subtest 'domain and folder' => sub {
        my $site = build_test_site(
            base_url => 'http://example.com/folder',
        );

        is $site->url( '/blog/2014/01/01/a-page.html' ),
           'http://example.com/folder/blog/2014/01/01/a-page.html';
        subtest 'index.html is removed' => sub {
            is $site->url( '/index.html' ),
               'http://example.com/folder/';
        };
    };

    subtest 'stores with base_url' => sub {
        my $site = build_test_site(
            deploy => {
                base_url => 'http://example.com/',
                path => '.',
            },
            base_url => '',
        );

        is $site->url( '/blog/2014/01/01/a-page.html' ), '/blog/2014/01/01/a-page.html';
        subtest 'index.html is removed' => sub {
            is $site->url( '/index.html' ), '/';
        };

        subtest 'current writing deploy overrides site base url' => sub {
            $site->_write_deploy( $site->_deploy );
            is $site->url( '/blog/2014/01/01/a-page.html' ), 'http://example.com/blog/2014/01/01/a-page.html';
            subtest 'index.html is removed' => sub {
                is $site->url( '/index.html' ), 'http://example.com/';
            };
        };
    };
};

done_testing;

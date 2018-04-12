
use Test::Lib;
use My::Test;
use TestApp;
my $SHARE_DIR = path( __DIR__ )->parent->child( 'share' );

my $site = build_test_site( theme => $SHARE_DIR->child( 'theme' ) );

subtest 'template' => sub {

    subtest 'default templates' => sub {
        my $app = TestApp->new(
            site => $site,
            url_root => '/blog/',
            pages => [],
            template_dir => 'blog',
        );

        subtest 'app template' => sub {
            my $tmpl = $app->template( 'index.html' );
            isa_ok $tmpl, 'Statocles::Template';
            is $tmpl->path, 'blog/index.html.ep';
        };

        subtest 'layout template' => sub {
            my $tmpl = $app->template( 'layout.html' );
            isa_ok $tmpl, 'Statocles::Template';
            is $tmpl->path, 'layout/default.html.ep';
        };

    };

    subtest 'overrides' => sub {
        my $app = TestApp->new(
            site => $site,
            url_root => '/blog/',
            pages => [],
            template_dir => 'blog',
            templates => {
                'index.html' => 'custom/blog/index.html',
                'layout.html' => 'custom/layout.html',
            },
        );

        subtest 'app template' => sub {
            my $tmpl = $app->template( 'index.html' );
            isa_ok $tmpl, 'Statocles::Template';
            is $tmpl->path, 'custom/blog/index.html.ep';
        };

        subtest 'layout template' => sub {
            my $tmpl = $app->template( 'layout.html' );
            isa_ok $tmpl, 'Statocles::Template';
            is $tmpl->path, 'custom/layout.html.ep';
        };
    };

    subtest 'site overrides default layout' => sub {
        my $site = build_test_site(
            theme => $SHARE_DIR->child( 'theme' ),
            templates => {
                'layout.html' => 'custom/layout.html',
            },
        );

        my $app = TestApp->new(
            site => $site,
            url_root => '/blog/',
            pages => [],
            template_dir => 'blog',
        );

        my $tmpl = $app->template( 'layout.html' );
        isa_ok $tmpl, 'Statocles::Template';
        is $tmpl->path, 'custom/layout.html.ep';
    };

};

done_testing;

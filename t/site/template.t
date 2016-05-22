
use Test::Lib;
use My::Test;
use Statocles::Site;
my $SHARE_DIR = path( __DIR__ )->parent->child( 'share' );

my $site = build_test_site( theme => $SHARE_DIR->child( 'theme' ) );

subtest 'template' => sub {

    subtest 'default templates' => sub {
        subtest 'meta template' => sub {
            my $tmpl = $site->template( 'robots.txt' );
            isa_ok $tmpl, 'Statocles::Template';
            is $tmpl->path, 'site/robots.txt.ep';
        };

        subtest 'layout template' => sub {
            my $tmpl = $site->template( 'layout.html' );
            isa_ok $tmpl, 'Statocles::Template';
            is $tmpl->path, 'layout/default.html.ep';
        };

    };

    subtest 'overrides' => sub {
        my $site = build_test_site(
            theme => $SHARE_DIR->child( 'theme' ),
            template_dir => 'site',
            templates => {
                'robots.txt' => 'custom/robots.txt',
                'layout.html' => 'custom/layout.html',
            },
        );

        subtest 'app template' => sub {
            my $tmpl = $site->template( 'robots.txt' );
            isa_ok $tmpl, 'Statocles::Template';
            is $tmpl->path, 'custom/robots.txt.ep';
        };

        subtest 'layout template' => sub {
            my $tmpl = $site->template( 'layout.html' );
            isa_ok $tmpl, 'Statocles::Template';
            is $tmpl->path, 'custom/layout.html.ep';
        };
    };
};

done_testing;

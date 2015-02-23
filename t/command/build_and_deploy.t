
use Statocles::Base 'Test';
use Capture::Tiny qw( capture );
use Statocles::Command;
my $SHARE_DIR = path( __DIR__, '..', 'share' );

sub test_site {
    my ( $root, @args ) = @_;
    my $debug = grep { /^-vv$/ } @args;
    return sub {
        my ( $out, $err, $exit ) = capture { Statocles::Command->main( @args ) };
        is $exit, 0, 'exit code';
        ok !$err, "no errors/warnings on stderr (debug: $debug)" or diag $err;
        ok $root->child( 'index.html' )->exists, 'index file exists';
        ok $root->child( 'sitemap.xml' )->exists, 'sitemap.xml exists';
        ok $root->child( 'blog', '2014', '04', '23', 'slug', 'index.html' )->exists;
        ok $root->child( 'blog', '2014', '04', '30', 'plug', 'index.html' )->exists;
        if ( $debug ) {
            subtest 'debug output is verbose' => sub {
                like $out, qr{Write file: /index[.]html};
                like $out, qr{Write file: sitemap[.]xml};
            };
        }
        else {
            ok !$out, 'no output without verbose' or diag $out;
        }
    };
}

subtest 'build site' => sub {
    my ( $tmp, $config_fn, $config ) = build_temp_site( $SHARE_DIR );

    my @args = (
        '--config' => "$config_fn",
        'build',
    );
    subtest 'default site' => test_site(
        $tmp->child( 'build_site' ),
        @args,
    );
    subtest 'custom site' => test_site(
        $tmp->child( 'build_foo' ),
        '--site' => 'site_foo',
        @args,
    );
    subtest 'verbose' => test_site(
        $tmp->child( 'build_site' ),
        @args,
        '-vv',
    );
};

subtest 'deploy site' => sub {
    my ( $tmp, $config_fn, $config ) = build_temp_site( $SHARE_DIR );

    my @args = (
        '--config' => "$config_fn",
        'deploy',
    );
    subtest 'default site' => test_site(
        $tmp->child( 'deploy_site' ),
        @args,
    );
    subtest 'custom site' => test_site(
        $tmp->child( 'deploy_foo' ),
        '--site' => 'site_foo',
        @args,
    );
    subtest 'verbose' => test_site(
        $tmp->child( 'deploy_site' ),
        @args,
        '-vv',
    );
};

done_testing;

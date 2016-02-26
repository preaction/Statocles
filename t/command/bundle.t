
use Test::Lib;
use My::Test;
use Capture::Tiny qw( capture );
use Statocles::Command;
my $SHARE_DIR = path( __DIR__, '..', 'share' );

my ( $tmp, $config_fn, $config ) = build_temp_site( $SHARE_DIR );

subtest 'theme' => sub {
    my $theme_dir = $tmp->child( qw( new_theme ) );
    my @args = (
        '--config' => "$config_fn",
        bundle => theme => 'default', "$theme_dir"
    );
    my @site_layout = qw( new_theme site layout.html.ep );
    my @site_footer = qw( new_theme site footer.html.ep );

    subtest 'first time creates directories' => sub {
        my ( $out, $err, $exit ) = capture { Statocles::Command->main( @args ) };
        #; diag `find $tmp`;
        is $exit, 0;
        ok !$err, 'nothing on stderr' or diag "STDERR: $err";
        like $out, qr(Theme "default" written to "$theme_dir");
        like $out, qr{Make sure to update "$config_fn"};
        is $tmp->child( @site_layout )->slurp_utf8,
            $SHARE_DIR->parent->parent->child( qw( share theme default site layout.html.ep ) )->slurp_utf8;
        ok $tmp->child( @site_footer )->is_file;
    };

    subtest 'second time does not overwrite hooks' => sub {
        # Write new hooks
        $tmp->child( @site_footer )->spew( 'SITE FOOTER' );
        # Templates will get overwritten no matter what
        $tmp->child( @site_layout )->spew( 'TEMPLATE DAMAGED' );

        my ( $out, $err, $exit ) = capture { Statocles::Command->main( @args ) };
        is $exit, 0;
        ok !$err, 'nothing on stderr' or diag "STDERR: $err";
        like $out, qr(Theme "default" written to "$theme_dir");
        like $out, qr{Make sure to update "$config_fn"};

        is $tmp->child( @site_layout )->slurp_utf8,
            $SHARE_DIR->parent->parent->child( qw( share theme default site layout.html.ep ) )->slurp_utf8;
        is $tmp->child( @site_footer )->slurp_utf8, 'SITE FOOTER';
    };

    subtest 'do not mention updating config if unnecessary' => sub {

        subtest 'absolute theme dir' => sub {
            $config->{theme}{args}{store} = $tmp->child( 'new_theme' );
            $config_fn->spew( YAML::Dump( $config ) );

            my ( $out, $err, $exit ) = capture { Statocles::Command->main( @args ) };

            is $exit, 0;
            ok !$err, 'nothing on stderr' or diag "STDERR: $err";
            like $out, qr(Theme "default" written to "$theme_dir");
            unlike $out, qr{Make sure to update "$config_fn"};
        };

        subtest 'relative theme dir' => sub {
            $config->{theme}{args}{store} = $tmp->child( 'new_theme' )->relative( $tmp );
            $config_fn->spew( YAML::Dump( $config ) );

            my $cwd = Path::Tiny->cwd;
            chdir $tmp;
            my ( $out, $err, $exit ) = capture { Statocles::Command->main( @args ) };
            chdir $cwd;

            is $exit, 0;
            ok !$err, 'nothing on stderr' or diag "STDERR: $err";
            like $out, qr(Theme "default" written to "$theme_dir");
            unlike $out, qr{Make sure to update "$config_fn"};
        };

        $config->{theme}{args}{store} = $tmp->child( 'theme' );
        $config_fn->spew( YAML::Dump( $config ) );
    };

    subtest 'errors' => sub {
        subtest 'no theme name to bundle' => sub {
            my @args = (
                '--config' => "$config_fn",
                bundle => 'theme',
            );
            my ( $out, $err, $exit ) = capture { Statocles::Command->main( @args ) };
            isnt $exit, 0;
            ok !$out, 'nothing on stdout' or diag "STDOUT: $out";
            like $err, qr{ERROR: No theme name!}, 'error message';
            like $err, qr{Usage:}, 'incorrect usage gets usage info';
        };

        subtest 'no directory to store in' => sub {
            my @args = (
                '--config' => "$config_fn",
                bundle => 'theme', 'default',
            );
            my ( $out, $err, $exit ) = capture { Statocles::Command->main( @args ) };
            isnt $exit, 0;
            ok !$out, 'nothing on stdout' or diag "STDOUT: $out";
            like $err, qr{ERROR: Must give a destination directory!}, 'error message';
            like $err, qr{Usage:}, 'incorrect usage gets usage info';
        };

    };
};

done_testing;

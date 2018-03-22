
use Test::Lib;
use My::Test;
use Capture::Tiny qw( capture );
use Statocles::Command;
my $SHARE_DIR = path( __DIR__, '..', 'share' );
use constant WIN32 => $^O =~ /Win32/;
require Win32::File if WIN32;

sub make_writable {
    return if !WIN32;
    for (@_) {
        if (-d) {
            make_writable($_->children);
        } else {
            Win32::File::GetAttributes($_, my $attr);
            Win32::File::SetAttributes($_, $attr & ~Win32::File::READONLY());
        }
    }
}

my ( $tmp, $config_fn, $config ) = build_temp_site( $SHARE_DIR );
$tmp->child( 'theme' )->remove_tree; # Delete the old theme

subtest 'theme' => sub {
    my $theme_dir = $tmp->child( qw( theme ) );
    my @args = (
        '--config' => "$config_fn",
        bundle => theme => 'default',
    );
    my @site_layout = qw( theme layout default.html.ep );
    my @site_footer = qw( theme site footer.html.ep );

    subtest 'first time creates directories' => sub {
        my ( $out, $err, $exit ) = capture { Statocles::Command->main( @args ) };
        #; diag `find $tmp`;
        is $exit, 0;
        ok !$err, 'nothing on stderr' or diag "STDERR: $err";
        like $out, qr(Theme "default" written to "$theme_dir");
        is $tmp->child( @site_layout )->slurp_utf8,
            $SHARE_DIR->parent->parent->child( qw( share theme default layout default.html.ep ) )->slurp_utf8;
        ok $tmp->child( @site_footer )->is_file;
    };

    subtest 'second time does not overwrite hooks' => sub {
        # Write new hooks
        my $footer = $tmp->child( @site_footer );
        make_writable($footer); # needed on Windows else rename fails
        $footer->spew( 'SITE FOOTER' );
        # Templates will get overwritten no matter what
        my $layout = $tmp->child( @site_layout );
        make_writable($layout); # needed on Windows else rename fails
        $layout->spew( 'TEMPLATE DAMAGED' );

        my ( $out, $err, $exit ) = capture { Statocles::Command->main( @args ) };
        is $exit, 0;
        ok !$err, 'nothing on stderr' or diag "STDERR: $err";
        like $out, qr(Theme "default" written to "$theme_dir");

        is $tmp->child( @site_layout )->slurp_utf8,
            $SHARE_DIR->parent->parent->child( qw( share theme default layout default.html.ep ) )->slurp_utf8;
        is $tmp->child( @site_footer )->slurp_utf8, 'SITE FOOTER';
    };

    subtest 'only copy certain files' => sub {
        make_writable( $tmp->child( 'theme' ) );
        $tmp->child( 'theme' )->remove_tree; # Delete the old theme
        my @args = (
            '--config' => "$config_fn",
            bundle => theme => 'default',
            'blog/index.rss.ep', 'blog/index.atom.ep',
            'site/sitemap.xml.ep', 'site/robots.txt.ep',
        );

        my ( $out, $err, $exit ) = capture { Statocles::Command->main( @args ) };
        #; diag `find $tmp`;
        is $exit, 0;
        ok !$err, 'nothing on stderr' or diag "STDERR: $err";
        like $out, qr(Theme "default" written to "$theme_dir");
        is $tmp->child( qw( theme blog index.rss.ep ) )->slurp_utf8,
            $SHARE_DIR->parent->parent->child( qw( share theme default blog index.rss.ep ) )->slurp_utf8;
        ok $tmp->child( qw( theme blog index.atom.ep ) )->is_file;
        ok $tmp->child( qw( theme site sitemap.xml.ep ) )->is_file;
        ok $tmp->child( qw( theme site robots.txt.ep ) )->is_file;
        ok !$tmp->child( qw( theme layout default.html.ep ) )->is_file, 'layout is not bundled';
        ok !$tmp->child( qw( theme blog index.html.ep ) )->is_file, 'blog index is not bundled';
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

    };
};

done_testing;

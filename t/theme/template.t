use Test::Lib;
use My::Test;
use Statocles::Theme;
use Statocles::Template;
use Cwd qw( getcwd );
use Scalar::Util qw( refaddr );
my $SHARE_DIR = path( __DIR__, '..', 'share' );
build_test_site( theme => $SHARE_DIR->child( 'theme' ) );

subtest 'templates from directory' => sub {
    subtest 'absolute directory' => sub {
        my $theme = Statocles::Theme->new(
            path => $SHARE_DIR->child( 'theme' ),
        );

        my $tmpl = $theme->template( 'blog', 'post.html' );
        isa_ok $tmpl, 'Statocles::Template';
        is $tmpl->path, 'blog/post.html.ep', 'path is correct';
        is $tmpl->theme, $theme, 'theme is correct';

        $tmpl = $theme->template( 'blog/post.html' );
        isa_ok $tmpl, 'Statocles::Template';
        is $tmpl->path, 'blog/post.html.ep', 'path is correct';
        is $tmpl->theme, $theme, 'theme is correct';

        $tmpl = $theme->template( Path::Tiny->new( 'blog', 'post.html' ) );
        isa_ok $tmpl, 'Statocles::Template';
        is $tmpl->path, 'blog/post.html.ep', 'path is correct';
        is $tmpl->theme, $theme, 'theme is correct';
    };

    subtest 'relative directory' => sub {
        my $cwd = getcwd();
        chdir $SHARE_DIR;

        my $theme = Statocles::Theme->new(
            store => 'theme',
        );

        my $tmpl = $theme->template( 'blog', 'post.html' );
        isa_ok $tmpl, 'Statocles::Template';
        is $tmpl->path, 'blog/post.html.ep', 'path is correct';
        is $tmpl->theme, $theme, 'theme is correct';

        $tmpl = $theme->template( 'blog/post.html' );
        isa_ok $tmpl, 'Statocles::Template';
        is $tmpl->path, 'blog/post.html.ep', 'path is correct';
        is $tmpl->theme, $theme, 'theme is correct';

        $tmpl = $theme->template( Path::Tiny->new( 'blog', 'post.html' ) );
        isa_ok $tmpl, 'Statocles::Template';
        is $tmpl->path, 'blog/post.html.ep', 'path is correct';
        is $tmpl->theme, $theme, 'theme is correct';

        chdir $cwd;
    };

    subtest 'default Statocles theme' => sub {
        my $theme = Statocles::Theme->new(
            store => '::default',
        );
        my $theme_path = path(qw( theme default ));
        like $theme->path, qr{\Q$theme_path\E$}
    };
};

subtest 'template from raw content' => sub {
    my $theme = Statocles::Theme->new(
        store => $SHARE_DIR->child( 'theme' ),
    );

    my $content = <<'ENDTMPL';
<h1><%= $title %></h1>
%= include 'include/test.markdown.ep', title => "Other Title"
ENDTMPL

    my %vars = (
        title => 'Page Title',
    );

    my $expect = <<'ENDHTML';
<h1>Page Title</h1>
<h1>Other Title</h1>

ENDHTML

    my $tmpl = $theme->build_template( "test/path.html", $content );
    eq_or_diff $tmpl->render( %vars ), $expect;
};

subtest 'theme caching' => sub {
    my $theme = Statocles::Theme->new(
        store => '::default',
    );

    my $tmpl = $theme->template( site => 'sitemap.xml' );
    $theme->clear;
    isnt refaddr $theme->template( site => 'sitemap.xml' ), refaddr $tmpl, 'new object created';
};

subtest 'include_paths' => sub {
    my $theme = Statocles::Theme->new(
        path => '::default',
        include_paths => [
            $SHARE_DIR->child( 'theme_include' ),
        ],
    );

    my $content = <<'ENDTMPL';
<h1><%= $title %></h1>
%= include 'include/in_include_store.markdown.ep'
%= include 'include/in_both.markdown.ep'
ENDTMPL

    my %vars = (
        title => 'Page Title',
    );

    my $expect = <<'ENDHTML';
<h1>Page Title</h1>
# In Include Store

# In Both

ENDHTML

    my $tmpl = $theme->build_template( "test/path.html", $content );
    eq_or_diff $tmpl->render( %vars ), $expect;

    subtest 'include not found' => sub {
        my $tmpl = $theme->build_template( "test/path.html", '%= include "NOT_FOUND"' );
        throws_ok { $tmpl->render } qr{Error in template: Can not find include "NOT_FOUND" in include directories: "[^"]+/theme_include", "[^"]+/default"}
    };
};

subtest 'template directive config' => sub {
    my $theme = Statocles::Theme->new(
        path => '::default',
        tag_start => '[%',
        tag_end => '%]',
        line_start => "\036", # Something nobody will use
    );
    my $content = <<ENDTMPL;
[%= "hello" %]
% not you
ENDTMPL
    my $expect = <<'ENDHTML';
hello
% not you
ENDHTML
    my $tmpl = $theme->build_template( 'derp', $content );
    my $got = $tmpl->render;
    eq_or_diff $got, $expect;
};

subtest 'error messages' => sub {

    subtest 'template not found' => sub {
        my $theme = Statocles::Theme->new(
            path => '::default',
        );
        my $theme_path = $theme->path->stringify;
        throws_ok { $theme->template( DOES_NOT_EXIST => 'does_not_exist.html' ) }
            qr{ERROR: Template "DOES_NOT_EXIST/does_not_exist\.html\.ep" does not exist in theme directory "\Q$theme_path\E"};
    };

};

done_testing;

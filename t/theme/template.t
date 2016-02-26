use Test::Lib;
use My::Test;
use Statocles::Theme;
use Statocles::Template;
use Cwd qw( getcwd );
use Scalar::Util qw( refaddr );
my $SHARE_DIR = path( __DIR__, '..', 'share' );
build_test_site( theme => $SHARE_DIR->child( 'theme' ) );

subtest 'attributes' => sub {
    subtest 'store is required' => sub {
        throws_ok { Statocles::Theme->new( ) } qr/store/ or diag $@;
    };
};

sub read_templates {
    my ( $store, $theme ) = @_;

    my $dir = $store->path;

    my $tmpl_fn = $dir->child( 'blog', 'post.html.ep' );
    my $tmpl = Statocles::Template->new(
        path => $tmpl_fn->relative( $dir ),
        content => $tmpl_fn->slurp_utf8,
        store => $store,
        theme => $theme,
    );

    my $index_fn = $dir->child( 'blog', 'index.html.ep' );
    my $index = Statocles::Template->new(
        path => $index_fn->relative( $dir ),
        content => $index_fn->slurp_utf8,
        store => $store,
        theme => $theme,
    );

    my $rss_fn = $dir->child( 'blog', 'index.rss.ep' );
    my $rss = Statocles::Template->new(
        path => $rss_fn->relative( $dir ),
        content => $rss_fn->slurp_utf8,
        store => $store,
        theme => $theme,
    );

    my $atom_fn = $dir->child( 'blog', 'index.atom.ep' );
    my $atom = Statocles::Template->new(
        path => $atom_fn->relative( $dir ),
        content => $atom_fn->slurp_utf8,
        store => $store,
        theme => $theme,
    );

    my $layout_fn = $dir->child( 'site', 'layout.html.ep' );
    my $layout = Statocles::Template->new(
        path => $layout_fn->relative( $dir ),
        content => $layout_fn->slurp_utf8,
        store => $store,
        theme => $theme,
    );

    my $extra_fn = $dir->child( 'site', 'include', 'extra.html.ep' );
    my $extra = Statocles::Template->new(
        path => $extra_fn->relative( $dir ),
        content => $extra_fn->slurp_utf8,
        store => $store,
        theme => $theme,
    );

    return (
        'blog/post.html' => $tmpl,
        'blog/index.html' => $index,
        'blog/index.rss' => $rss,
        'blog/index.atom' => $atom,
        'site/layout.html' => $layout,
        'site/include/extra.html' => $extra,
    );
}

subtest 'templates from directory' => sub {
    my @templates = (
        'blog/post.html',
        'blog/index.html',
        'blog/index.rss',
        'blog/index.atom',
        'site/layout.html',
        'site/include/extra.html',
    );

    subtest 'absolute directory' => sub {
        my $store = Statocles::Store->new(
            path => $SHARE_DIR->child( 'theme' ),
        );
        my $theme = Statocles::Theme->new(
            store => $SHARE_DIR->child( 'theme' ),
        );
        my %exp_templates = read_templates( $store, $theme );
        for my $tmpl ( @templates ) {
            subtest $tmpl => sub {
                cmp_deeply $theme->template( split m{/}, $tmpl ), $exp_templates{ $tmpl }, 'array of path parts';
                cmp_deeply $theme->template( $tmpl ), $exp_templates{ $tmpl }, 'path with slashes';
                cmp_deeply $theme->template( Path::Tiny->new( split m{/}, $tmpl ) ), $exp_templates{ $tmpl }, 'Path::Tiny object';
            };
        }
    };

    subtest 'relative directory' => sub {
        my $cwd = getcwd();
        chdir $SHARE_DIR;

        my $store = Statocles::Store->new(
            path => 'theme',
        );

        my $theme = Statocles::Theme->new(
            store => 'theme',
        );
        my %exp_templates = read_templates( $store, $theme );

        for my $tmpl ( @templates ) {
            subtest $tmpl => sub {
                cmp_deeply $theme->template( split m{/}, $tmpl ), $exp_templates{ $tmpl }, 'array of path parts';
                cmp_deeply $theme->template( $tmpl ), $exp_templates{ $tmpl }, 'path with slashes';
                cmp_deeply $theme->template( Path::Tiny->new( split m{/}, $tmpl ) ), $exp_templates{ $tmpl }, 'Path::Tiny object';
            };
        }

        chdir $cwd;
    };

    subtest 'default Statocles theme' => sub {
        my $theme = Statocles::Theme->new(
            store => '::default',
        );
        my $theme_path = path(qw( theme default ));
        like $theme->store->path, qr{\Q$theme_path\E$}
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

subtest 'include_stores' => sub {
    my $theme = Statocles::Theme->new(
        store => '::default',
        include_stores => [
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

subtest 'error messages' => sub {

    subtest 'template not found' => sub {
        my $theme = Statocles::Theme->new(
            store => '::default',
        );
        my $theme_path = $theme->store->path->stringify;
        throws_ok { $theme->template( DOES_NOT_EXIST => 'does_not_exist.html' ) }
            qr{ERROR: Template "DOES_NOT_EXIST/does_not_exist\.html\.ep" does not exist in theme directory "\Q$theme_path\E"};
    };

};

done_testing;

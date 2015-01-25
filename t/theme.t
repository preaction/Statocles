
use Statocles::Base 'Test';
use Statocles::Theme;
use Statocles::Template;
use Cwd qw( getcwd );
use Scalar::Util qw( refaddr );
my $SHARE_DIR = path( __DIR__, 'share' );
build_test_site();

subtest 'attributes' => sub {
    subtest 'store is required' => sub {
        throws_ok { Statocles::Theme->new( ) } qr/store/ or diag $@;
    };
};

sub read_templates {
    my ( $store ) = @_;

    my $dir = $store->path;

    my $tmpl_fn = $dir->child( 'blog', 'post.html.ep' );
    my $tmpl = Statocles::Template->new(
        path => $tmpl_fn->relative( $dir ),
        content => $tmpl_fn->slurp,
        store => $store,
    );

    my $index_fn = $dir->child( 'blog', 'index.html.ep' );
    my $index = Statocles::Template->new(
        path => $index_fn->relative( $dir ),
        content => $index_fn->slurp,
        store => $store,
    );

    my $rss_fn = $dir->child( 'blog', 'index.rss.ep' );
    my $rss = Statocles::Template->new(
        path => $rss_fn->relative( $dir ),
        content => $rss_fn->slurp,
        store => $store,
    );

    my $atom_fn = $dir->child( 'blog', 'index.atom.ep' );
    my $atom = Statocles::Template->new(
        path => $atom_fn->relative( $dir ),
        content => $atom_fn->slurp,
        store => $store,
    );

    my $layout_fn = $dir->child( 'site', 'layout.html.ep' );
    my $layout = Statocles::Template->new(
        path => $layout_fn->relative( $dir ),
        content => $layout_fn->slurp,
        store => $store,
    );

    return (
        blog => {
            'post.html' => $tmpl,
            'index.html' => $index,
            'index.rss' => $rss,
            'index.atom' => $atom,
        },
        site => {
            'layout.html' => $layout,
        },
    );
}

subtest 'templates from directory' => sub {
    my @templates = (
        [ blog => 'post.html' ],
        [ blog => 'index.html' ],
        [ blog => 'index.rss' ],
        [ blog => 'index.atom' ],
        [ site => 'layout.html' ],
    );

    subtest 'absolute directory' => sub {
        my $store = Statocles::Store::File->new(
            path => $SHARE_DIR->child( 'theme' ),
        );
        my %exp_templates = read_templates( $store );
        my $theme = Statocles::Theme->new(
            store => $SHARE_DIR->child( 'theme' ),
        );
        for my $tmpl ( @templates ) {
            cmp_deeply $theme->template( @$tmpl ), $exp_templates{ $tmpl->[0] }{ $tmpl->[1] };
        }
    };

    subtest 'relative directory' => sub {
        my $cwd = getcwd();
        chdir $SHARE_DIR;

        my $store = Statocles::Store::File->new(
            path => 'theme',
        );

        my %exp_templates = read_templates( $store );
        my $theme = Statocles::Theme->new(
            store => 'theme',
        );
        for my $tmpl ( @templates ) {
            cmp_deeply $theme->template( @$tmpl ), $exp_templates{ $tmpl->[0] }{ $tmpl->[1] };
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

subtest 'theme caching' => sub {
    my $theme = Statocles::Theme->new(
        store => '::default',
    );

    my $tmpl = $theme->template( site => 'sitemap.xml' );
    $theme->clear;
    isnt refaddr $theme->template( site => 'sitemap.xml' ), refaddr $tmpl, 'new object created';
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

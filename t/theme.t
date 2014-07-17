
use Statocles::Test;
use Statocles::Theme;
use Statocles::Template;
use Cwd qw( getcwd );
my $SHARE_DIR = path( __DIR__, 'share' );

subtest 'getting templates' => sub {
    my $line = __LINE__ + 1;
    my $theme = Statocles::Theme->new(
        templates => {
            blog => {
                post => Statocles::Template->new(
                    content => '<% $content %>',
                ),
            },
        },
    );

    cmp_deeply $theme->template( blog => 'post' ),
        Statocles::Template->new(
            path => 't/theme.t line ' . $line,
            content => '<% $content %>',
        );
};

subtest 'theme coercion' => sub {
    my $coerce = Statocles::Theme->coercion;
    my $theme = $coerce->( $SHARE_DIR->child( 'theme' ) );
    isa_ok $theme, 'Statocles::Theme';
    is $theme->store->path, $SHARE_DIR->child( 'theme' );
};

sub read_templates {
    my ( $dir ) = @_;

    $dir = path( $dir );

    my $tmpl_fn = $dir->child( 'blog', 'post.html.ep' );
    my $tmpl = Statocles::Template->new(
        path => $tmpl_fn,
    );
    my $index_fn = $dir->child( 'blog', 'index.html.ep' );
    my $index = Statocles::Template->new(
        path => $index_fn,
    );
    my $rss_fn = $dir->child( 'blog', 'index.rss.ep' );
    my $rss = Statocles::Template->new(
        path => $rss_fn,
    );
    my $atom_fn = $dir->child( 'blog', 'index.atom.ep' );
    my $atom = Statocles::Template->new(
        path => $atom_fn,
    );
    my $layout_fn = $dir->child( 'site', 'layout.html.ep' );
    my $layout = Statocles::Template->new(
        path => $layout_fn,
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
    subtest 'absolute directory' => sub {
        my %exp_templates = read_templates( $SHARE_DIR->child( 'theme' ) );
        my $theme = Statocles::Theme->new(
            store => $SHARE_DIR->child( 'theme' ),
        );
        cmp_deeply $theme->templates, \%exp_templates;
        cmp_deeply $theme->template( blog => 'post.html' ), $exp_templates{blog}{'post.html'};
    };

    subtest 'absolute directory' => sub {
        my %exp_templates = read_templates( $SHARE_DIR->child( 'theme' ) );
        my $theme = Statocles::Theme->new(
            store => Statocles::Store->new( path => $SHARE_DIR->child( 'theme' ) ),
        );
        cmp_deeply $theme->templates, \%exp_templates;
        cmp_deeply $theme->template( blog => 'post.html' ), $exp_templates{blog}{'post.html'};
    };

    subtest 'relative directory' => sub {
        my $cwd = getcwd();
        chdir $SHARE_DIR;

        my %exp_templates = read_templates( 'theme' );
        my $theme = Statocles::Theme->new(
            store => 'theme',
        );
        cmp_deeply $theme->templates, \%exp_templates;
        cmp_deeply $theme->template( blog => 'post.html' ), $exp_templates{blog}{'post.html'};

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

done_testing;

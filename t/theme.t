
use Statocles::Test;
use Statocles::Theme;
use Statocles::Template;
use Cwd qw( getcwd );
my $SHARE_DIR = catdir( __DIR__, 'share' );

subtest 'getting templates' => sub {
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
            content => '<% $content %>',
        );
};

sub read_templates {
    my ( $dir ) = @_;

    my $tmpl_fn = catfile( $dir, 'blog', 'post.tmpl' );
    my $tmpl = Statocles::Template->new(
        path => $tmpl_fn,
    );
    my $index_fn = catfile( $dir, 'blog', 'index.tmpl' );
    my $index = Statocles::Template->new(
        path => $index_fn,
    );
    my $layout_fn = catfile( $dir, 'site', 'layout.tmpl' );
    my $layout = Statocles::Template->new(
        path => $layout_fn,
    );

    return (
        blog => {
            post => $tmpl,
            index => $index,
        },
        site => {
            layout => $layout,
        },
    );
}

subtest 'templates from directory' => sub {
    subtest 'absolute directory' => sub {
        my %exp_templates = read_templates( catdir( $SHARE_DIR, 'theme' ) );
        my $theme = Statocles::Theme->new(
            source_dir => catdir( $SHARE_DIR, 'theme' ),
        );
        cmp_deeply $theme->templates, \%exp_templates;
        cmp_deeply $theme->template( blog => 'post' ), $exp_templates{blog}{post};
    };

    subtest 'relative directory' => sub {
        my $cwd = getcwd();
        chdir $SHARE_DIR;

        my %exp_templates = read_templates( 'theme' );
        my $theme = Statocles::Theme->new(
            source_dir => 'theme',
        );
        cmp_deeply $theme->templates, \%exp_templates;
        cmp_deeply $theme->template( blog => 'post' ), $exp_templates{blog}{post};

        chdir $cwd;
    };
};

done_testing;

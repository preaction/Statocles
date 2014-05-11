
use Statocles::Test;
use Statocles::Theme;
use Text::Template;
use Cwd qw( getcwd );
my $SHARE_DIR = catdir( __DIR__, 'share' );

subtest 'getting templates' => sub {
    my $theme = Statocles::Theme->new(
        templates => {
            blog => {
                post => Text::Template->new(
                    TYPE => 'STRING',
                    SOURCE => '{$content}',
                ),
            },
        },
    );

    cmp_deeply $theme->template( blog => 'post' ),
        Text::Template->new(
            TYPE => 'STRING',
            SOURCE => '{$content}',
        );
};

subtest 'templates from directory' => sub {
    my $cwd = getcwd();

    chdir catdir( $SHARE_DIR, 'theme', 'blog' );
    my $tmpl = Text::Template->new(
        TYPE => 'FILE',
        SOURCE => 'post.tmpl',
    ) or die "Could not make template: $Text::Template::ERROR";
    my $blog_index = Text::Template->new(
        TYPE => 'FILE',
        SOURCE => 'index.tmpl',
    ) or die "Could not make template: $Text::Template::ERROR";
    chdir catdir( $SHARE_DIR, 'theme', 'site' );
    my $layout = Text::Template->new(
        TYPE => 'FILE',
        SOURCE => 'layout.tmpl',
    ) or die "Could not make template: $Text::Template::ERROR";
    chdir $cwd;

    my %exp_templates = (
        blog => {
            post => $tmpl,
            index => $blog_index,
        },
        site => {
            layout => $layout,
        },
    );

    subtest 'absolute directory' => sub {
        my $theme = Statocles::Theme->new(
            source_dir => catdir( $SHARE_DIR, 'theme' ),
        );
        cmp_deeply $theme->templates, \%exp_templates;
        cmp_deeply $theme->template( blog => 'post' ), $tmpl;
    };

    subtest 'relative directory' => sub {
        chdir $SHARE_DIR;

        my $theme = Statocles::Theme->new(
            source_dir => 'theme',
        );
        cmp_deeply $theme->templates, \%exp_templates;
        cmp_deeply $theme->template( blog => 'post' ), $tmpl;

        chdir $cwd;
    };
};

done_testing;

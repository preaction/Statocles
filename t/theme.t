
use Statocles::Test;
use Statocles::Theme;
use Text::Template;
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
    my $theme = Statocles::Theme->new(
        source_dir => catdir( $SHARE_DIR, 'theme' ),
    );

    my $tmpl = Text::Template->new(
        TYPE => 'FILE',
        SOURCE => catfile( $SHARE_DIR, 'theme', 'blog', 'post.tmpl' ),
    ) or die "Could not make template: $Text::Template::ERROR";
    my $blog_index = Text::Template->new(
        TYPE => 'FILE',
        SOURCE => catfile( $SHARE_DIR, 'theme', 'blog', 'index.tmpl' ),
    ) or die "Could not make template: $Text::Template::ERROR";
    my $layout = Text::Template->new(
        TYPE => 'FILE',
        SOURCE => catfile( $SHARE_DIR, 'theme', 'site', 'layout.tmpl' ),
    ) or die "Could not make template: $Text::Template::ERROR";

    cmp_deeply $theme->templates, {
        blog => {
            post => $tmpl,
            index => $blog_index,
        },
        site => {
            layout => $layout,
        },
    };

    cmp_deeply $theme->template( blog => 'post' ), $tmpl;
};

done_testing;


use Statocles::Test;
use Statocles::Theme;
use Text::Template;
my $SHARE_DIR = catdir( __DIR__, '..', 'share' );

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
    cmp_deeply $theme->template( blog => 'post' ),
        Text::Template->new(
            TYPE => 'FILE',
            SOURCE => catfile( $SHARE_DIR, 'theme', 'blog', 'post' ),
        );
};

done_testing;

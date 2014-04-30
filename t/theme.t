
use Statocles::Test;
use Statocles::Theme;
use Text::Template;

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

done_testing;

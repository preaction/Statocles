
use Statocles::Test;
my $SHARE_DIR = catdir( __DIR__, 'share' );

use Statocles::Document;
use Statocles::Page;
use Text::Markdown;

my $doc = Statocles::Document->new(
    title => 'Page Title',
    author => 'preaction',
    content => <<'MARKDOWN',
# Subtitle

This is a paragraph of markdown.

## Subtitle 2

This is another paragraph of markdown.
MARKDOWN
);
my $md = Text::Markdown->new;

subtest 'simple page (default template)' => sub {
    my $page = Statocles::Page->new(
        document => $doc,
    );

    my $output = $page->render;
    eq_or_diff $output, $md->markdown( $doc->content );
};

subtest 'template string' => sub {
    my $page = Statocles::Page->new(
        document => $doc,
        template => '{$title} {$author} {$content}',
    );

    my $output = $page->render;
    my $expect = join " ", $doc->title, $doc->author, $md->markdown( $doc->content );
    eq_or_diff $output, $expect;
};

subtest 'template file' => sub {
    my $page = Statocles::Page->new(
        document => $doc,
        template => Text::Template->new(
            type => 'FILE',
            source => catfile( $SHARE_DIR, 'tmpl', 'page.tmpl' ),
        ),
    );

    my $output = $page->render;
    my $expect = join "\n", $doc->title, $doc->author, $md->markdown( $doc->content ), '';
    eq_or_diff $output, $expect;
};

subtest 'layout' => sub {
    my $page = Statocles::Page->new(
        document => $doc,
        template => '{$title} {$author} {$content}',
        layout => 'HEAD { $content } FOOT',
    );

    my $output = $page->render;
    my $expect = join " ", 'HEAD', $doc->title, $doc->author, $md->markdown( $doc->content ), 'FOOT';
    eq_or_diff $output, $expect;
};

subtest 'extra args' => sub {
    my $page = Statocles::Page->new(
        document => $doc,
        template => '{ $site } {$title} {$author} {$content}',
        layout => '{ $site } HEAD { $content } FOOT',
    );

    my $output = $page->render( site => 'hello', title => 'DOES NOT OVERRIDE', );
    my $expect = join " ", 'hello', 'HEAD', 'hello', $doc->title, $doc->author, $md->markdown( $doc->content ), 'FOOT';
    eq_or_diff $output, $expect;
};

subtest 'invalid template coercions' => sub {
    throws_ok {
        Statocles::Page->new(
            document => $doc,
            template => undef,
        );
    } qr{Template is undef};
};

subtest 'template errors' => sub {
    subtest 'main template error' => sub {
        dies_ok {
            Statocles::Page->new(
                document => $doc,
                template => Text::Template->new(
                    type => 'STRING',
                    source => '}',
                ),
            )->render;
        };
    };
    subtest 'layout template error' => sub {
        dies_ok {
            Statocles::Page->new(
                document => $doc,
                layout => Text::Template->new(
                    type => 'STRING',
                    source => '}',
                ),
            )->render;
        };
    };
};

done_testing;

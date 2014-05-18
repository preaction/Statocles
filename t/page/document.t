
use Statocles::Test;
my $SHARE_DIR = catdir( __DIR__, '..', 'share' );

use Statocles::Document;
use Statocles::Page::Document;
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
    my $page = Statocles::Page::Document->new(
        document => $doc,
    );

    my $output = $page->render;
    eq_or_diff $output, $md->markdown( $doc->content ) . "\n\n";
};

subtest 'template string' => sub {
    my $page = Statocles::Page::Document->new(
        document => $doc,
        template => '<%= $title %> <%= $author %> <%= $content %>',
    );

    my $output = $page->render;
    my $expect = join " ", $doc->title, $doc->author, $md->markdown( $doc->content ) . "\n\n";
    eq_or_diff $output, $expect;
};

subtest 'layout' => sub {
    my $page = Statocles::Page::Document->new(
        document => $doc,
        template => '<%= $title %> <%= $author %> <%= $content %>',
        layout => 'HEAD <%= $content %> FOOT',
    );

    my $output = $page->render;
    my $expect = join " ", 'HEAD', $doc->title, $doc->author, $md->markdown( $doc->content ) . "\n", 'FOOT' . "\n";
    eq_or_diff $output, $expect;
};

subtest 'extra args' => sub {
    my $page = Statocles::Page::Document->new(
        document => $doc,
        template => '<%= $site %> <%= $title %> <%= $author %> <%= $content %>',
        layout => '<%= $site %> HEAD <%= $content %> FOOT',
    );

    my $output = $page->render( site => 'hello', title => 'DOES NOT OVERRIDE', );
    my $expect = join " ", 'hello', 'HEAD', 'hello', $doc->title, $doc->author, $md->markdown( $doc->content ) . "\n", 'FOOT' . "\n";
    eq_or_diff $output, $expect;
};

subtest 'invalid template coercions' => sub {
    throws_ok {
        Statocles::Page::Document->new(
            document => $doc,
            template => undef,
        );
    } qr{Template is undef};
};

done_testing;

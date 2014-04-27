
use Staticly::Test;
my $SHARE_DIR = catdir( __DIR__, 'share' );

use Staticly::Document;
use Staticly::Page;
use Text::Markdown;

my $doc = Staticly::Document->new(
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
    my $page = Staticly::Page->new(
        document => $doc,
    );

    my $output = $page->render;
    eq_or_diff $output, $md->markdown( $doc->content );
};

subtest 'template string' => sub {
    my $page = Staticly::Page->new(
        document => $doc,
        template => '{$title} {$author} {$content}',
    );

    my $output = $page->render;
    my $expect = join " ", $doc->title, $doc->author, $md->markdown( $doc->content );
    eq_or_diff $output, $expect;
};

subtest 'template file' => sub {
    my $page = Staticly::Page->new(
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

subtest 'write to disk (default template)' => sub {
    my $tmp = File::Temp->newdir;
    my $page = Staticly::Page->new(
        document => $doc,
        path => 'document.html',
    );
    $page->write( $tmp->dirname );
    my $path = catfile( $tmp->dirname, 'document.html' );
    ok -f $path, 'file exists';
    eq_or_diff scalar read_file( $path ), $md->markdown( $doc->content ), 'content is correct';
};

done_testing;

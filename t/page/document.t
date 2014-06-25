
use Statocles::Test;
my $SHARE_DIR = path( __DIR__ )->parent->child( 'share' );

use Statocles::Document;
use Statocles::Page::Document;
use Text::Markdown;

my $doc = Statocles::Document->new(
    path => '/path/to/document.yml',
    title => 'Page Title',
    author => 'preaction',
    content => <<'MARKDOWN',
# Subtitle

This is a paragraph of markdown.

## Subtitle 2

This is another paragraph of markdown.

---

This is a second section of content

MARKDOWN
);
my $md = Text::Markdown->new;

subtest 'template string' => sub {
    my $tp = Time::Piece->new;

    my $page = Statocles::Page::Document->new(
        document => $doc,
        path => '/path/to/page.html',
        published => $tp,
        template => join( ' ',
            ( map { "<\%= \$self->$_ \%>" } qw( published path ) ),
            ( map { "<\%= \$doc->$_ \%>" } qw( title author ) ),
            '<%= $content %>',
        ),
    );

    my $output = $page->render;
    my $expect = join " ", $page->published, $page->path, $doc->title, $doc->author,
        $md->markdown( $doc->content ) . "\n\n";
    eq_or_diff $output, $expect;
};

subtest 'layout' => sub {
    my $page = Statocles::Page::Document->new(
        document => $doc,
        path => '/path/to/page.html',
        template => join( ' ',
            '<%= $self->path %>',
            ( map { "<\%= \$doc->$_ \%>" } qw( title author ) ),
            '<%= $content %>',
        ),
        layout => 'HEAD <%= $content %> FOOT',
    );

    my $output = $page->render;
    my $expect = join " ", 'HEAD', $page->path, $doc->title, $doc->author,
        $md->markdown( $doc->content ) . "\n", 'FOOT' . "\n";
    eq_or_diff $output, $expect;
};

subtest 'extra args' => sub {
    my $page = Statocles::Page::Document->new(
        document => $doc,
        path => '/path/to/page.html',
        template => join( ' ',
            '<%= $site %>',
            ( map { "<\%= \$self->$_ \%>" } qw( path ) ),
            ( map { "<\%= \$doc->$_ \%>" } qw( title author ) ),
            '<%= $content %>',
        ),
        layout => '<%= $site %> HEAD <%= $content %> FOOT',
    );

    my $output = $page->render( site => 'hello', title => 'DOES NOT OVERRIDE', );
    my $expect = join " ", 'hello', 'HEAD', 'hello', $page->path, $doc->title,
        $doc->author, $md->markdown( $doc->content ) . "\n", 'FOOT' . "\n";
    eq_or_diff $output, $expect;
};

subtest 'content sections' => sub {
    my $page = Statocles::Page::Document->new(
        document => $doc,
        path => '/path/to/page.html',
        template => <<'ENDTEMPLATE',
% my @sections = $self->sections;
<%= $sections[0] %>
% if ( @sections > 1 ) {
MORE...
% }
ENDTEMPLATE
    );

    my $output = $page->render;
    my @sections = split /\n---\n/, $doc->content;
    my $expect = join "\n", $md->markdown( $sections[0] ), "MORE...", "", "";
    eq_or_diff $output, $expect;
};

done_testing;

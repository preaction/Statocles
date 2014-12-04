
use Statocles::Test;
my $SHARE_DIR = path( __DIR__ )->parent->child( 'share' );

use Statocles::Document;
use Statocles::Page::Document;
use Text::Markdown;

my $doc = Statocles::Document->new(
    path => '/path/to/document.yml',
    title => 'Page Title',
    author => 'preaction',
    tags => [qw( foo bar baz )],
    last_modified => Time::Piece->new( time - 600 ),
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

subtest 'page last modified' => sub {
    subtest 'defaults to document last modified' => sub {

        my $page = Statocles::Page::Document->new(
            document => $doc,
            path => '/path/to/page.html',
        );

        isa_ok $page->last_modified, 'Time::Piece';
        is $page->last_modified->datetime, $doc->last_modified->datetime;
    };

    subtest 'overridden by published date' => sub {
        my $tp = Time::Piece->new;
        my $page = Statocles::Page::Document->new(
            document => $doc,
            path => '/path/to/page.html',
            published => $tp,
        );

        isa_ok $page->last_modified, 'Time::Piece';
        is $page->last_modified->datetime, $tp->datetime;
    };
};

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

subtest 'page tags' => sub {
    my $page = Statocles::Page::Document->new(
        document => $doc,
        path => '/path/to/page.html',
        tags => [
            {
                title => 'foo',
                href => '/path/to/foo.html',
            },
            {
                title => 'bar',
                href => '/path/to/bar.html',
            },
            {
                title => 'baz',
                href => '/path/to/baz.html',
            },
        ],
        template => <<'ENDTEMPLATE',
% for my $link ( @{ $self->tags } ) {
<%= $link->{title} %>: <%= $link->{href} %>
% }
ENDTEMPLATE
    );

    my $output = $page->render;
    my $expect = join "\n", ( map { join ": ", $_->{title}, $_->{href} } @{ $page->tags } ), "", "";
    eq_or_diff $output, $expect;

    subtest 'default' => sub {
        my $page = Statocles::Page::Document->new(
            document => $doc,
            path => '/path/to/page.html',
            template => <<'ENDTEMPLATE',
% for my $link ( @{ $self->tags } ) {
<%= $link->{title} %>: <%= $link->{href} %>
% }
ENDTEMPLATE
        );
        my $output;
        lives_ok { $output = $page->render };
        is $output, "\n";
    };
};

done_testing;


use Statocles::Base 'Test';
my $SHARE_DIR = path( __DIR__ )->parent->child( 'share' );

use Statocles::Document;
use Statocles::Page::Document;
use Text::Markdown;
use Statocles::Site;
my $site = Statocles::Site->new( deploy => tempdir );

my $doc = Statocles::Document->new(
    path => '/path/to/document.markdown',
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

subtest 'constructor' => sub {

    test_constructor(
        'Statocles::Page::Document',
        required => {
            path => '/path/to/page.html',
            document => $doc,
        },
        default => {
            site => $Statocles::SITE,
            search_change_frequency => 'weekly',
            search_priority => 0.5,
            layout => sub {
                isa_ok $_, 'Statocles::Template';
                is $_->content, '<%= $content %>';
            },
            template => sub {
                isa_ok $_, 'Statocles::Template';
                is $_->content, '<%= $content %>';
            },
            last_modified => $doc->last_modified,
        },
    );

};

subtest 'page last modified overridden by published date' => sub {
    my $tp = Time::Piece->new;
    my $page = Statocles::Page::Document->new(
        document => $doc,
        path => '/path/to/page.html',
        last_modified => $tp,
    );

    isa_ok $page->last_modified, 'Time::Piece';
    is $page->last_modified->datetime, $tp->datetime;
};

subtest 'template string' => sub {
    my $tp = Time::Piece->new;

    my $page = Statocles::Page::Document->new(
        document => $doc,
        path => '/path/to/page.html',
        last_modified => $tp,
        template => join( ' ',
            ( map { "<\%= \$self->$_ \%>" } qw( last_modified path ) ),
            ( map { "<\%= \$doc->$_ \%>" } qw( title author ) ),
            '<%= $content %>',
        ),
    );

    my $output = $page->render;
    my $expect = join " ", $page->last_modified, $page->path, $doc->title, $doc->author,
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
% for my $link ( $self->tags ) {
<%= $link->title %>: <%= $link->href %>
% }
ENDTEMPLATE
    );

    my $output = $page->render;
    my $expect = join "\n", ( map { join ": ", $_->title, $_->href } $page->tags ), "", "";
    eq_or_diff $output, $expect;

    subtest 'default' => sub {
        my $page = Statocles::Page::Document->new(
            document => $doc,
            path => '/path/to/page.html',
            template => <<'ENDTEMPLATE',
% for my $link ( $self->tags ) {
<%= $link->title %>: <%= $link->href %>
% }
ENDTEMPLATE
        );
        my $output;
        lives_ok { $output = $page->render };
        is $output, "\n";
    };
};

subtest 'page includes' => sub {
    my $site = Statocles::Site->new(
        theme => $SHARE_DIR->child( 'theme' ),
        deploy => tempdir,
    );

    my $doc = Statocles::Document->new(
        path => '/path/to/document.markdown',
        title => 'Page Title',
        content => <<'MARKDOWN',
# Subtitle

This is a paragraph of markdown.

%= include "include/test.markdown.ep", title => $self->title
MARKDOWN
    );

    my $page = Statocles::Page::Document->new(
        document => $doc,
        path => '/path/to/page.html',
    );

    my $expect = <<'ENDHTML';
<h1>Subtitle</h1>

<p>This is a paragraph of markdown.</p>

<h1>Page Title</h1>


ENDHTML

    eq_or_diff $page->render, $expect;
};

done_testing;

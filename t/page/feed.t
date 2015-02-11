
use Statocles::Base 'Test';
use Statocles::Page::Document;
use Statocles::Document;
use Statocles::Page::List;
use Statocles::Page::Feed;

my $site = Statocles::Site->new( deploy => tempdir );

my @pages = (
    Statocles::Page::Document->new(
        last_modified => Time::Piece->strptime( '2014-06-04', '%Y-%m-%d' ),
        path => '/blog/2014/06/04/blug.html',
        document => Statocles::Document->new(
            path => '/2014/06/04/blug.markdown',
            title => 'Third post',
            author => 'preaction',
            content => 'Not as good body content',
        ),
    ),
    Statocles::Page::Document->new(
        last_modified => Time::Piece->strptime( '2014-04-30', '%Y-%m-%d' ),
        path => '/blog/2014/04/30/page.html',
        document => Statocles::Document->new(
            path => '/2014/04/30/page.markdown',
            title => 'Second post',
            author => 'preaction',
            content => 'Better body content',
        ),
    ),
    Statocles::Page::Document->new(
        last_modified => Time::Piece->strptime( '2014-04-23', '%Y-%m-%d' ),
        path => '/blog/2014/04/23/slug.html',
        document => Statocles::Document->new(
            path => '/2014/04/23/slug.markdown',
            title => 'First post',
            author => 'preaction',
            content => 'Body content',
        ),
    ),
);

my $list = Statocles::Page::List->new(
    path => '/blog/index.html',
    pages => \@pages,
);

subtest 'simple feed' => sub {
    my $feed = Statocles::Page::Feed->new(
        path => '/blog/index.rss',
        page => $list,
        template => <<'ENDTEMPLATE',
% for my $page ( @$pages ) {
% my $doc = $page->document;
<%= $page->last_modified %> <%= $page->path %> <%= $doc->title %> <%= $doc->author %> <%= $page->content %>
% }
ENDTEMPLATE
    );

    my $html =  join( "\n",
                map {
                    join( " ",
                        $_->last_modified, $_->path, $_->document->title,
                        $_->document->author, $_->content,
                    ),
                }
                @pages
            ) . "\n\n";

    eq_or_diff $feed->render, $html;
};

done_testing;

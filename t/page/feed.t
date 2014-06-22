
use Statocles::Test;
use Statocles::Page::Document;
use Statocles::Document;
use Statocles::Page::List;
use Statocles::Page::Feed;

my @pages = (
    Statocles::Page::Document->new(
        published => Time::Piece->strptime( '2014-06-04', '%Y-%m-%d' ),
        path => '/blog/2014/06/04/blug.html',
        document => Statocles::Document->new(
            path => '/2014/06/04/blug.yml',
            title => 'Third post',
            author => 'preaction',
            content => 'Not as good body content',
        ),
    ),
    Statocles::Page::Document->new(
        published => Time::Piece->strptime( '2014-04-30', '%Y-%m-%d' ),
        path => '/blog/2014/04/30/page.html',
        document => Statocles::Document->new(
            path => '/2014/04/30/page.yml',
            title => 'Second post',
            author => 'preaction',
            content => 'Better body content',
        ),
    ),
    Statocles::Page::Document->new(
        published => Time::Piece->strptime( '2014-04-23', '%Y-%m-%d' ),
        path => '/blog/2014/04/23/slug.html',
        document => Statocles::Document->new(
            path => '/2014/04/23/slug.yml',
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
    );

    my $html =  join( "\n",
                map {
                    join( " ",
                        $_->published, $_->path, $_->document->title,
                        $_->document->author, $_->content,
                    ),
                }
                @pages
            ) . "\n\n";

    eq_or_diff $feed->render, $html;
};

done_testing;


use Statocles::Test;
use Statocles::Page;
use Statocles::Document;
use Statocles::Page::List;

my @pages = (
    Statocles::Page->new(
        path => '/blog/2014/04/30/page.html',
        document => Statocles::Document->new(
            path => '/2014/04/30/page.yml',
            title => 'Second post',
            author => 'preaction',
            content => 'Better body content',
        ),
    ),
    Statocles::Page->new(
        path => '/blog/2014/04/23/slug.html',
        document => Statocles::Document->new(
            path => '/2014/04/23/slug.yml',
            title => 'First post',
            author => 'preaction',
            content => 'Body content',
        ),
    ),
);

subtest 'simple list (default templates)' => sub {
    my $list = Statocles::Page::List->new(
        pages => \@pages,
    );

    my $html =  join "\n",
                map {
                    join( " ", $_->document->title, $_->document->author, $_->content ),
                }
                @pages;

    eq_or_diff $list->render, $html;
};

done_testing;

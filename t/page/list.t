
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
        path => '/blog/index.html',
        pages => \@pages,
    );

    my $html =  join "\n",
                map {
                    join( " ", $_->document->title, $_->document->author, $_->content ),
                }
                @pages;

    eq_or_diff $list->render, $html;
};

subtest 'extra args' => sub {
    my $list = Statocles::Page::List->new(
        path => '/blog/index.html',
        pages => \@pages,
        layout => '{ $site } { $content }',
        template => '{ $site } { join "\n", map { join " ", $_->{title}, $_->{author}, $_->{content } } @pages }',
    );

    my $html    = "hello hello "
                . join "\n",
                    map { join( " ", $_->document->title, $_->document->author, $_->content ), }
                    @pages;

    my $output = $list->render( site => 'hello', title => 'DOES NOT OVERRIDE' );
    eq_or_diff $output, $html;
};

done_testing;

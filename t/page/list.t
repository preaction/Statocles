
use Statocles::Base 'Test';
use Statocles::Page::Document;
use Statocles::Document;
use Statocles::Page::List;

my $site = Statocles::Site->new( deploy => tempdir );

my @pages = (
    Statocles::Page::Document->new(
        date => Time::Piece->strptime( '2014-06-04', '%Y-%m-%d' ),
        path => '/blog/2014/06/04/blug.html',
        document => Statocles::Document->new(
            path => '/2014/06/04/blug.markdown',
            title => 'Third post',
            author => 'preaction',
            content => "Not as good body content",
        ),
    ),
    Statocles::Page::Document->new(
        date => Time::Piece->strptime( '2014-04-30', '%Y-%m-%d' ),
        path => '/blog/2014/04/30/page.html',
        document => Statocles::Document->new(
            path => '/2014/04/30/page.markdown',
            title => 'Second post',
            author => 'preaction',
            content => "Better body content\n---\nSecond section\n---\nThird section",
        ),
    ),
    Statocles::Page::Document->new(
        date => Time::Piece->strptime( '2014-04-23', '%Y-%m-%d' ),
        path => '/blog/2014/04/23/slug.html',
        document => Statocles::Document->new(
            path => '/2014/04/23/slug.markdown',
            title => 'First post',
            author => 'preaction',
            content => "Body content\n---\nSecond Section\n",
        ),
    ),
);

subtest 'attribute defaults' => sub {
    my $page = Statocles::Page::List->new(
        path => '/blog/index.html',
        pages => \@pages,
    );

    subtest 'search_change_frequency' => sub {
        is $page->search_change_frequency, 'daily';
    };

    subtest 'search_priority' => sub {
        is $page->search_priority, 0.3;
    };
};

subtest 'date' => sub {
    my $list = Statocles::Page::List->new(
        path => '/blog/index.html',
        pages => \@pages,
    );
    isa_ok $list->date, 'Time::Piece';
    is $list->date->datetime, $pages[0]->date->datetime;
};

subtest 'extra args' => sub {
    my $list = Statocles::Page::List->new(
        path => '/blog/index.html',
        pages => \@pages,
        next => '/blog/page-2.html',
        prev => '/blog/page--1.html',
        layout => '<%= $site %> <%= $content %>',
        template => <<'ENDTEMPLATE',
<%= $site %>
% for my $page ( @$pages ) {
% my $doc = $page->document;
<%= $page->date %> <%= $page->path %> <%= $doc->title %> <%= $doc->author %> <%= $page->content %>
% }
<%= $self->prev %>
<%= $self->next %>
ENDTEMPLATE
    );

    my $html    = "hello hello\n"
                . join( "\n",
                    map {
                        join( " ",
                            $_->date, $_->path, $_->document->title,
                            $_->document->author, $_->content,
                        )
                    }
                    @pages
                ) . "\n/blog/page--1.html\n/blog/page-2.html\n\n";

    my $output = $list->render( site => 'hello', title => 'DOES NOT OVERRIDE' );
    eq_or_diff $output, $html;
};

subtest 'content sections' => sub {
    my $list = Statocles::Page::List->new(
        path => '/blog/index.html',
        pages => \@pages,
        template => <<'ENDTEMPLATE',
% for my $page ( @$pages ) {
% my @sections = $page->sections;
<%= join "\n", grep { defined } @sections[0,1] %>
% if ( @sections > 2 ) {
MORE...
% }
% }
ENDTEMPLATE
    );

    my $output = $list->render;
    my $html = join "\n",
        $pages[0]->content, ($pages[1]->sections)[0,1],
        "MORE...", ($pages[2]->sections)[0,1], "", ""
        ;

    eq_or_diff $output, $html;
};

subtest 'pagination' => sub {
    subtest 'without index' => sub {
        subtest 'multiple pages' => sub {
            my @paged_lists = Statocles::Page::List->paginate(
                path => '/blog/page-%i.html',
                pages => \@pages,
                after => 1,
            );

            my @exp_pages = (
                Statocles::Page::List->new(
                    path => '/blog/page-1.html',
                    pages => [ $pages[0] ],
                    next => '/blog/page-2.html',
                    date => $pages[0]->date,
                ),
                Statocles::Page::List->new(
                    path => '/blog/page-2.html',
                    pages => [ $pages[1] ],
                    next => '/blog/page-3.html',
                    prev => '/blog/page-1.html',
                    date => $pages[0]->date,
                ),
                Statocles::Page::List->new(
                    path => '/blog/page-3.html',
                    pages => [ $pages[2] ],
                    prev => '/blog/page-2.html',
                    date => $pages[0]->date,
                ),
            );

            cmp_deeply \@paged_lists, \@exp_pages,
                or diag explain \@paged_lists, \@exp_pages;
            cmp_deeply \@paged_lists,
                array_each( methods( date => $pages[0]->date ) ),
                'all paginated pages have the same date';
        };
        subtest 'single page' => sub {
            my @paged_lists = Statocles::Page::List->paginate(
                path => '/blog/page-%i.html',
                pages => \@pages,
                after => scalar @pages,
            );

            my @exp_pages = (
                Statocles::Page::List->new(
                    path => '/blog/page-1.html',
                    pages => [ @pages ],
                    date => $pages[0]->date,
                ),
            );

            cmp_deeply \@paged_lists, \@exp_pages,
                or diag explain \@paged_lists, \@exp_pages;
            cmp_deeply \@paged_lists,
                array_each( methods( date => $pages[0]->date ) ),
                'all paginated pages have the same date';
        };
    };

    subtest 'with index' => sub {
        subtest 'multiple pages' => sub {
            my @paged_lists = Statocles::Page::List->paginate(
                path => '/blog/page-%i.html',
                pages => \@pages,
                after => 1,
                index => '/blog/index.html',
            );

            my @exp_pages = (
                Statocles::Page::List->new(
                    path => '/blog/index.html',
                    pages => [ $pages[0] ],
                    next => '/blog/page-2.html',
                    date => $pages[0]->date,
                ),
                Statocles::Page::List->new(
                    path => '/blog/page-2.html',
                    pages => [ $pages[1] ],
                    next => '/blog/page-3.html',
                    prev => '/blog',
                    date => $pages[0]->date,
                ),
                Statocles::Page::List->new(
                    path => '/blog/page-3.html',
                    pages => [ $pages[2] ],
                    prev => '/blog/page-2.html',
                    date => $pages[0]->date,
                ),
            );

            cmp_deeply \@paged_lists, \@exp_pages,
                or diag explain \@paged_lists, \@exp_pages;
        };
        subtest 'single page' => sub {
            my @paged_lists = Statocles::Page::List->paginate(
                path => '/blog/page-%i.html',
                index => '/blog/index.html',
                pages => \@pages,
                after => scalar @pages,
            );

            my @exp_pages = (
                Statocles::Page::List->new(
                    path => '/blog/index.html',
                    pages => [ @pages ],
                    date => $pages[0]->date,
                ),
            );

            cmp_deeply \@paged_lists, \@exp_pages,
                or diag explain \@paged_lists, \@exp_pages;
            cmp_deeply \@paged_lists,
                array_each( methods( date => $pages[0]->date ) ),
                'all paginated pages have the same date';
        };
    };

    subtest 'with directories' => sub {
        subtest 'multiple pages' => sub {
            my @paged_lists = Statocles::Page::List->paginate(
                path => '/blog/page/%i/index.html',
                pages => \@pages,
                after => 1,
                index => '/blog/index.html',
            );

            my @exp_pages = (
                Statocles::Page::List->new(
                    path => '/blog/index.html',
                    pages => [ $pages[0] ],
                    next => '/blog/page/2',
                    date => $pages[0]->date,
                ),
                Statocles::Page::List->new(
                    path => '/blog/page/2/index.html',
                    pages => [ $pages[1] ],
                    next => '/blog/page/3',
                    prev => '/blog',
                    date => $pages[0]->date,
                ),
                Statocles::Page::List->new(
                    path => '/blog/page/3/index.html',
                    pages => [ $pages[2] ],
                    prev => '/blog/page/2',
                    date => $pages[0]->date,
                ),
            );

            cmp_deeply \@paged_lists, \@exp_pages,
                or diag explain \@paged_lists, \@exp_pages;
        };
        subtest 'single page' => sub {
            my @paged_lists = Statocles::Page::List->paginate(
                path => '/blog/page/%i/index.html',
                index => '/blog/index.html',
                pages => \@pages,
                after => scalar @pages,
            );

            my @exp_pages = (
                Statocles::Page::List->new(
                    path => '/blog/index.html',
                    pages => [ @pages ],
                    date => $pages[0]->date,
                ),
            );

            cmp_deeply \@paged_lists, \@exp_pages,
                or diag explain \@paged_lists, \@exp_pages;
            cmp_deeply \@paged_lists,
                array_each( methods( date => $pages[0]->date ) ),
                'all paginated pages have the same date';
        };
    };
};

done_testing;

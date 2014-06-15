
use Statocles::Test;
use Statocles::Page::Document;
use Statocles::Document;
use Statocles::Page::List;

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

subtest 'simple list (default templates)' => sub {
    my $list = Statocles::Page::List->new(
        path => '/blog/index.html',
        pages => \@pages,
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

    eq_or_diff $list->render, $html;
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
<%= $page->published %> <%= $page->path %> <%= $doc->title %> <%= $doc->author %> <%= $page->content %>
% }
<%= $self->prev %>
<%= $self->next %>
ENDTEMPLATE
    );

    my $html    = "hello hello\n"
                . join( "\n",
                    map {
                        join( " ",
                            $_->published, $_->path, $_->document->title,
                            $_->document->author, $_->content,
                        )
                    }
                    @pages
                ) . "\n/blog/page--1.html\n/blog/page-2.html\n\n";

    my $output = $list->render( site => 'hello', title => 'DOES NOT OVERRIDE' );
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
                ),
                Statocles::Page::List->new(
                    path => '/blog/page-2.html',
                    pages => [ $pages[1] ],
                    next => '/blog/page-3.html',
                    prev => '/blog/page-1.html',
                ),
                Statocles::Page::List->new(
                    path => '/blog/page-3.html',
                    pages => [ $pages[2] ],
                    prev => '/blog/page-2.html',
                ),
            );

            cmp_deeply \@paged_lists, \@exp_pages,
                or diag explain \@paged_lists, \@exp_pages;
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
                ),
            );

            cmp_deeply \@paged_lists, \@exp_pages,
                or diag explain \@paged_lists, \@exp_pages;
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
                ),
                Statocles::Page::List->new(
                    path => '/blog/page-2.html',
                    pages => [ $pages[1] ],
                    next => '/blog/page-3.html',
                    prev => '/blog/index.html',
                ),
                Statocles::Page::List->new(
                    path => '/blog/page-3.html',
                    pages => [ $pages[2] ],
                    prev => '/blog/page-2.html',
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
                ),
            );

            cmp_deeply \@paged_lists, \@exp_pages,
                or diag explain \@paged_lists, \@exp_pages;
        };
    };
};

done_testing;

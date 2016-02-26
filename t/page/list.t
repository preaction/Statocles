use Test::Lib;
use My::Test;
use Statocles::Site;
use Statocles::Page::Document;
use Statocles::Document;
use Statocles::Page::List;

my $site = Statocles::Site->new( deploy => tempdir, title => 'Test Site' );

my @pages = (
    Statocles::Page::Document->new(
        date => DateTimeObj->coerce( '2014-06-04' ),
        path => '/blog/2014/06/04/blug.html',
        document => Statocles::Document->new(
            path => '/2014/06/04/blug.markdown',
            title => 'Third post',
            author => 'preaction',
            content => "Not as good body content",
            links => {
                stylesheet => [
                    {
                        href => '/css/style.css',
                    },
                ],
                canonical => [
                    {
                        href => 'http://example.com/',
                    },
                ],
            },
        ),
    ),
    Statocles::Page::Document->new(
        date => DateTimeObj->coerce( '2014-04-30' ),
        path => '/blog/2014/04/30/page.html',
        document => Statocles::Document->new(
            path => '/2014/04/30/page.markdown',
            title => 'Second post',
            author => 'preaction',
            content => "Better body content\n---\nSecond section\n---\nThird section",
            links => {
                stylesheet => [
                    {
                        href => '/css/style.css',
                    },
                    {
                        href => '/css/style2.css',
                    },
                ],
                script => [
                    {
                        href => '/js/app.js',
                    },
                ],
            },
        ),
    ),
    Statocles::Page::Document->new(
        date => DateTimeObj->coerce( '2014-08-23' ),
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
    isa_ok $list->date, 'DateTime::Moonpig';
    is $list->date->datetime, $pages[2]->date->datetime;
};

subtest 'extra args' => sub {
    my $list = Statocles::Page::List->new(
        path => '/blog/index.html',
        pages => \@pages,
        next => '/blog/page-2.html',
        prev => '/blog/page--1.html',
        layout => '<%= $foo %> <%= $content %>',
        template => <<'ENDTEMPLATE',
<%= $foo %>
<%= $site->title %>
% for my $page ( @$pages ) {
% my $doc = $page->document;
<%= $page->date %> <%= $page->path %> <%= $doc->title %> <%= $doc->author %> <%= $page->content %>
% }
<%= $self->prev %>
<%= $self->next %>
ENDTEMPLATE
    );

    my $html    = "hello hello\n"
                . $site->title . "\n"
                . join( "\n",
                    map {
                        join( " ",
                            $_->date, $_->path, $_->document->title,
                            $_->document->author, $_->content,
                        )
                    }
                    @pages
                ) . "\n/blog/page--1.html\n/blog/page-2.html\n\n";

    my $output = $list->render( foo => 'hello', title => 'DOES NOT OVERRIDE' );
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

subtest 'links' => sub {

    subtest 'script and stylesheets from children are added' => sub {
        # Should be added before list to allow for overriding?
        my $list = Statocles::Page::List->new(
            path => '/blog/index.html',
            pages => \@pages,
            links => {
                stylesheet => [
                    Statocles::Link->new(
                        href => '/css/list.css',
                    ),
                ],
                script => [
                    Statocles::Link->new(
                        href => '/js/list.js',
                    ),
                ],
                canonical => [
                    Statocles::Link->new(
                        href => 'http://www.example.org',
                    ),
                ],
            },
        );

        cmp_deeply [ $list->links( 'stylesheet' ) ],
            [
                Statocles::Link->new(
                    href => '/css/style.css',
                ),
                Statocles::Link->new(
                    href => '/css/style2.css',
                ),
                Statocles::Link->new(
                    href => '/css/list.css',
                ),
            ],
            'stylesheet links combined from child pages, children first';

        cmp_deeply [ $list->links( 'script' ) ],
            [
                Statocles::Link->new(
                    href => '/js/app.js',
                ),
                Statocles::Link->new(
                    href => '/js/list.js',
                ),
            ],
            'script links combined from child pages, children first';

        cmp_deeply [ $list->links( 'canonical' ) ],
            [ Statocles::Link->new( href => 'http://www.example.org' ) ],
            'canonical link from children are not added';

        subtest 'adding links appends on the list only' => sub {
            my $ret = $list->links( stylesheet => '/css/list-2.css' );
            ok !$ret, 'nothing returned';

            cmp_deeply $list->_links->{stylesheet},
                [
                    Statocles::Link->new(
                        href => '/css/list.css',
                    ),
                    Statocles::Link->new(
                        href => '/css/list-2.css',
                    ),
                ],
                'link is added to list links';

            ok !(
                    grep { $_->href eq '/css/list-2.css' }
                    map { $_->links( 'stylesheet' ) }
                    @pages
                ),
                'link is not added to any child page';
        };
    };
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
                    date => $pages[2]->date,
                ),
                Statocles::Page::List->new(
                    path => '/blog/page-2.html',
                    pages => [ $pages[1] ],
                    next => '/blog/page-3.html',
                    prev => '/blog/page-1.html',
                    date => $pages[2]->date,
                ),
                Statocles::Page::List->new(
                    path => '/blog/page-3.html',
                    pages => [ $pages[2] ],
                    prev => '/blog/page-2.html',
                    date => $pages[2]->date,
                ),
            );

            cmp_deeply \@paged_lists, \@exp_pages,
                or diag explain \@paged_lists, \@exp_pages;
            cmp_deeply \@paged_lists,
                array_each( methods( date => $pages[2]->date ) ),
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
                    date => $pages[2]->date,
                ),
            );

            cmp_deeply \@paged_lists, \@exp_pages,
                or diag explain \@paged_lists, \@exp_pages;
            cmp_deeply \@paged_lists,
                array_each( methods( date => $pages[2]->date ) ),
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
                    date => $pages[2]->date,
                ),
                Statocles::Page::List->new(
                    path => '/blog/page-2.html',
                    pages => [ $pages[1] ],
                    next => '/blog/page-3.html',
                    prev => '/blog',
                    date => $pages[2]->date,
                ),
                Statocles::Page::List->new(
                    path => '/blog/page-3.html',
                    pages => [ $pages[2] ],
                    prev => '/blog/page-2.html',
                    date => $pages[2]->date,
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
                    date => $pages[2]->date,
                ),
            );

            cmp_deeply \@paged_lists, \@exp_pages,
                or diag explain \@paged_lists, \@exp_pages;
            cmp_deeply \@paged_lists,
                array_each( methods( date => $pages[2]->date ) ),
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
                    date => $pages[2]->date,
                ),
                Statocles::Page::List->new(
                    path => '/blog/page/2/index.html',
                    pages => [ $pages[1] ],
                    next => '/blog/page/3',
                    prev => '/blog',
                    date => $pages[2]->date,
                ),
                Statocles::Page::List->new(
                    path => '/blog/page/3/index.html',
                    pages => [ $pages[2] ],
                    prev => '/blog/page/2',
                    date => $pages[2]->date,
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
                    date => $pages[2]->date,
                ),
            );

            cmp_deeply \@paged_lists, \@exp_pages,
                or diag explain \@paged_lists, \@exp_pages;
            cmp_deeply \@paged_lists,
                array_each( methods( date => $pages[2]->date ) ),
                'all paginated pages have the same date';
        };
    };
};

done_testing;

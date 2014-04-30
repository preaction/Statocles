
use Statocles::Test;
use Statocles::Document;
use Statocles::File;
use Statocles::Page;
use Statocles::Theme;
use Statocles::App::Blog;
use Text::Template;

subtest 'blog post' => sub {
    my $doc = Statocles::Document->new(
        file => Statocles::File->new(
            path => '/path/to/blog/2014/01/01/slug.yml',
        ),
        title => 'First Post',
        author => 'preaction',
        content => 'Body content',
    );

    my $md = Text::Markdown->new;

    my $theme = Statocles::Theme->new(
        templates => {
            blog => {
                post => Text::Template->new(
                    TYPE => 'STRING',
                    SOURCE => '{ $title } { $author } { $content }',
                ),
            },
        },
    );

    my $app = Statocles::App::Blog->new(
        source_dir => '/path/to/blog',
        url_root => '/blog',
        theme => $theme,
        documents => [ $doc ],
    );

    my @pages = $app->blog_pages;
    cmp_deeply \@pages, [
        Statocles::Page->new(
            template => $theme->template( blog => 'post' ),
            path => '/blog/2014/01/01/slug.html',
            document => $doc,
        ),
    ];

    my $html = $pages[0]->render;
    eq_or_diff $html, join( " ", $doc->title, $doc->author, $md->markdown( $doc->content ) );
};

done_testing;

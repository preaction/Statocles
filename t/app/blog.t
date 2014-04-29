
use Statocles::Test;
use Statocles::Document;
use Statocles::File;
use Statocles::Page;
use Statocles::App::Blog;

subtest 'blog post' => sub {
    my $doc = Statocles::Document->new(
        file => Statocles::File->new(
            path => '/path/to/blog/2014/01/01/slug.yml',
        ),
        title => 'First Post',
        author => 'preaction',
        content => 'Body content',
    );

    my $app = Statocles::App::Blog->new(
        source_dir => '/path/to/blog',
        url_root => '/blog',
        documents => [ $doc ],
    );
    my @pages = $app->blog_pages;
    cmp_deeply \@pages, [
        Statocles::Page->new(
            path => '/blog/2014/01/01/slug.html',
            document => $doc,
        ),
    ];
};

done_testing;

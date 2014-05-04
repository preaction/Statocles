
use Statocles::Test;
use Statocles::Theme;
use Statocles::Store;
use Statocles::App::Blog;
use Text::Template;
my $SHARE_DIR = catdir( __DIR__, '..', 'share' );

my $theme = Statocles::Theme->new(
    templates => {
        site => {
            layout => Text::Template->new(
                TYPE => 'STRING',
                SOURCE => 'HEAD { $content } FOOT',
            ),
        },
        blog => {
            post => Text::Template->new(
                TYPE => 'STRING',
                SOURCE => '{ $title } { $author } { $content }',
            ),
        },
    },
);

my $md = Text::Markdown->new;
my $tmpdir = File::Temp->newdir;

my $app = Statocles::App::Blog->new(
    source => Statocles::Store->new( path => catdir( $SHARE_DIR, 'blog' ) ),
    destination => Statocles::Store->new( path => catdir( $tmpdir->dirname ) ),
    url_root => '/blog',
    theme => $theme,
);

subtest 'blog post' => sub {
    my @doc_paths = (
        catfile( '', '2014', '04', '23', 'slug.yml' ),
        catfile( '', '2014', '04', '30', 'plug.yml' ),
    );
    my @pages;
    for my $doc_path ( @doc_paths ) {
        my $doc = Statocles::Document->new(
            path => $doc_path,
            %{ YAML::LoadFile( catfile( $SHARE_DIR, 'blog', $doc_path ) ) },
        );

        my $page_path = catfile( '/', 'blog', $doc_path );
        $page_path =~ s{/{2,}}{/}g;
        $page_path =~ s/[.]yml$/.html/;

        my $page = Statocles::Page->new(
            template => $theme->template( blog => 'post' ),
            layout => $theme->template( site => 'layout' ),
            path => $page_path,
            document => $doc,
        );

        push @pages, $page;
    }

    cmp_deeply
        [ $app->post_pages ],
        \@pages;

    $app->write;

    for my $page ( @pages ) {
        my $path = catfile( $tmpdir->dirname, $page->path );
        ok -e $path;
        eq_or_diff scalar read_file( $path ), $page->render;
    }
};

done_testing;

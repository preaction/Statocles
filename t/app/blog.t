
use Statocles::Test;
use Statocles::Theme;
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

subtest 'blog post' => sub {
    my $md = Text::Markdown->new;

    my $app = Statocles::App::Blog->new(
        source_dir => catdir( $SHARE_DIR, 'blog' ),
        url_root => '/blog',
        theme => $theme,
    );

    my $exp_file = Statocles::File->new(
        path => catfile( $SHARE_DIR, 'blog', '2014', '04', '23', 'slug.yml' ),
    );
    $exp_file->read;
    cmp_deeply
        [ $app->pages ],
        [
            Statocles::Page->new(
                template => $theme->template( blog => 'post' ),
                layout => $theme->template( site => 'layout' ),
                path => '/blog/2014/04/23/slug.html',
                document => $exp_file->documents->[0],
            ),
        ];

    my $tmpdir = File::Temp->newdir;
    $app->write( $tmpdir->dirname );

    my $path = catfile( $tmpdir->dirname, 'blog', '2014', '04', '23', 'slug.html' );
    my $html = join( " ", 'HEAD', 'First Post', 'preaction', $md->markdown( 'Body content' ), 'FOOT' );
    ok -e $path;
    eq_or_diff scalar read_file( $path ), $html;
};

done_testing;

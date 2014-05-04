
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

subtest 'blog post' => sub {
    my $md = Text::Markdown->new;
    my $tmpdir = File::Temp->newdir;

    my $app = Statocles::App::Blog->new(
        source => Statocles::Store->new( path => catdir( $SHARE_DIR, 'blog' ) ),
        destination => Statocles::Store->new( path => catdir( $tmpdir->dirname ) ),
        url_root => '/blog',
        theme => $theme,
    );

    my $doc_rel_path = '/' . catfile( '2014', '04', '23', 'slug.yml' );
    my $doc_path = catfile( $SHARE_DIR, 'blog', $doc_rel_path );
    my $doc = YAML::LoadFile( $doc_path );

    cmp_deeply
        [ $app->pages ],
        [
            Statocles::Page->new(
                template => $theme->template( blog => 'post' ),
                layout => $theme->template( site => 'layout' ),
                path => '/blog/2014/04/23/slug.html',
                document => Statocles::Document->new( path => $doc_rel_path, %$doc ),
            ),
        ];

    $app->write;

    my $path = catfile( $tmpdir->dirname, 'blog', '2014', '04', '23', 'slug.html' );
    my $html = join( " ", 'HEAD', 'First Post', 'preaction', $md->markdown( 'Body content' ), 'FOOT' );
    ok -e $path;
    eq_or_diff scalar read_file( $path ), $html;
};

done_testing;

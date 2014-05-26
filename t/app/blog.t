
use Statocles::Test;
use Statocles::Theme;
use Statocles::Store;
use Statocles::App::Blog;
use Statocles::Template;
my $SHARE_DIR = catdir( __DIR__, '..', 'share' );

my $theme = Statocles::Theme->new(
    templates => {
        site => {
            layout => Statocles::Template->new(
                content => 'HEAD <%= $content %> FOOT',
            ),
        },
        blog => {
            index => Statocles::Template->new(
                content => <<'ENDTEMPLATE'
% for my $page ( @$pages ) {
<% $page->{title} %> <% $page->{author} %> <% $page->{content} %>
% }
ENDTEMPLATE
            ),
            post => Statocles::Template->new(
                content => '<%= $title %> <%= $author %> <%= $content %>',
            ),
        },
    },
);

my $md = Text::Markdown->new;
my $tmpdir = File::Temp->newdir;

my $app = Statocles::App::Blog->new(
    source => Statocles::Store->new( path => catdir( $SHARE_DIR, 'blog' ) ),
    url_root => '/blog',
    theme => $theme,
);

my @got_pages = $app->pages;

subtest 'blog post pages' => sub {
    my @doc_paths = (
        [ '2014', '04', '23', 'slug.yml' ],
        [ '2014', '04', '30', 'plug.yml' ],
        [ '2014', '05', '22', '(regex)[name].file.yml' ],
    );
    my @pages;
    for my $doc_path ( @doc_paths ) {
        my $doc = Statocles::Document->new(
            path => catfile( '', @$doc_path ),
            %{ YAML::LoadFile( catfile( $SHARE_DIR, 'blog', @$doc_path ) ) },
        );

        my $page_path = join '/', '', 'blog', @$doc_path;
        $page_path =~ s/[.]yml$/.html/;

        my $page = Statocles::Page::Document->new(
            template => $theme->template( blog => 'post' ),
            layout => $theme->template( site => 'layout' ),
            path => $page_path,
            document => $doc,
        );

        push @pages, $page;
    }

    cmp_deeply
        [ $app->post_pages ],
        bag( @pages );
};

subtest 'index page' => sub {
    my $page = Statocles::Page::List->new(
        path => '/blog/index.html',
        template => $theme->template( blog => 'index' ),
        layout => $theme->template( site => 'layout' ),
        pages => [ $app->post_pages ],
    );

    cmp_deeply $app->index, $page;
};

done_testing;

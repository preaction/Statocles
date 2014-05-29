
use Statocles::Test;
use Capture::Tiny qw( capture );
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
            %{ $app->source->read_document( catfile( $SHARE_DIR, 'blog', @$doc_path ) ) },
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
        # Sorting by path just happens to also sort by date
        pages => [ sort { $b->path cmp $a->path } $app->post_pages ],
    );

    cmp_deeply $app->index, $page;
};

subtest 'commands' => sub {
    # We need an app we can edit
    my $tmpdir = File::Temp->newdir;
    my $app = Statocles::App::Blog->new(
        source => Statocles::Store->new( path => catdir( $tmpdir->dirname, 'blog' ) ),
        url_root => '/blog',
        theme => $theme,
    );

    subtest 'help' => sub {
        my @args = qw( blog help );
        my ( $out, $err, $exit ) = capture { $app->command( @args ) };
        ok !$err, 'blog help is on stdout';
        is $exit, 0;
        like $out, qr{blog post <title> -- Create a new blog post},
            'contains blog help information';
    };

    subtest 'post' => sub {
        subtest 'create new post' => sub {
            local $ENV{EDITOR}; # We can't very well open vim...
            my ( undef, undef, undef, $day, $mon, $year ) = localtime;
            my $doc_path = catfile(
                $tmpdir->dirname,
                'blog',
                sprintf( '%04i', $year + 1900 ),
                sprintf( '%02i', $mon + 1 ),
                sprintf( '%02i', $day ),
                'this-is-a-title.yml',
            );

            subtest 'run the command' => sub {
                my @args = qw( blog post This is a Title );
                my ( $out, $err, $exit ) = capture { $app->command( @args ) };
                ok !$err, 'nothing on stdout';
                is $exit, 0;
                like $out, qr{New post at: \Q$doc_path},
                    'contains blog post document path';
            };

            subtest 'check the generated document' => sub {
                my $doc = $app->source->read_document( $doc_path );
                cmp_deeply $doc, {
                    title => 'This is a Title',
                    author => '',
                    content => <<'ENDMARKDOWN',
Markdown content goes here.
ENDMARKDOWN
                };
                eq_or_diff scalar read_file( $doc_path ), <<'ENDCONTENT';
---
author: ''
title: This is a Title
---
Markdown content goes here.
ENDCONTENT
            };
        };
    };
};

done_testing;

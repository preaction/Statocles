
# Check the syntax of all the built-in theme bundles
use Test::Lib;
use My::Test;
$Statocles::VERSION = '0.000001';
use Statocles::Document;
use Statocles::Page::List;
use Statocles::Page::Document;
use Statocles::App::Blog;
use Statocles::Site;
use Statocles::Theme;
use Statocles::Link;
use Mojo::DOM;
use Mojo::Util qw( xml_escape );

my $THEME_DIR = path( __DIR__, '..', '..', 'share', 'theme' );

my %document_common = (
    links => {
        stylesheet => [
            {
                href => '/theme/css/special.css',
            },
        ],
        script => [
            {
                href => '/theme/js/special.js',
            },
        ],
    },
);

my %document = (
    normal => Statocles::Document->new(
        path => 'DUMMY',
        title => 'Page Title',
        author => 'Doug "preaction" Bell',
        content => 'Content One',
        date => '2015-01-01 00:00:00',
        tags => [qw( foo bar <baz> )],
        %document_common,
    ),
    escaped => Statocles::Document->new(
        path => '/$escape/@this/(correctly)/index.html',
        title => '<ESCAPE>',
        content => qq{<b>Must not be escaped</b>\n\n---\n\nSection 2},
        date => '2015-01-02 00:00:00',
        # No tags, to test what happens with tag displays
        # No author, to show the site author instead
        %document_common,
    ),
);

my $blog = Statocles::App::Blog->new(
    url_root => '/blog',
    store => '.',
    tag_text => {
        foo => <<ENDMARKDOWN,
# Foo!

Bar, baz, and fuzz!
ENDMARKDOWN
    },
);

my %default_site = (
    author => 'Doug Bell <doug@example.com>',
    base_url => 'http://example.com',
    build_store => '.',
    deploy => '.',
    title => '<Site Title>',
    theme => '.',
    apps => {
        blog => $blog,
    },
    images => {
        icon => {
           src => '/favicon.ico',
        },
    },
    links => {
        stylesheet => [
            {
                href => '/theme/css/site-style.css',
            },
        ],
        script => [
            {
                href => '/theme/js/site-script.js',
            },
        ],
    },
);

my %site = (
    default => Statocles::Site->new(
        %default_site,
    ),

    google_analytics => Statocles::Site->new(
        %default_site,
        data => {
            google_analytics_id => 'GA-123456-8',
        },
    ),

);

my %page = (
    normal => Statocles::Page::Document->new(
        path => 'document.html',
        document => $document{normal},
        tags => [
            Statocles::Link->new(
                href => '/blog/tag/foo',
                text => 'foo',
            ),
            Statocles::Link->new(
                href => '/blog/tag/bar',
                text => 'bar',
            ),
            Statocles::Link->new(
                href => '/blog/tag/baz',
                text => '<baz>',
            ),
        ],
        _content_sections => {
            map {; $_ => qq{<i id="$_-content-section"></i>} } qw( tags feeds ),
        },
    ),
    escaped => Statocles::Page::Document->new(
        path => '/$escape/@this/(correctly)/index.html',
        document => $document{escaped},
        _content_sections => {
            map {; $_ => qq{<i id="$_-content-section"></i>} } qw( tags feeds ),
        },
    ),

);

# Set this so that the blog can get its tags
$blog->_post_pages( [ $page{normal} ] );

$page{ list_first } = Statocles::Page::List->new(
    app => $blog,
    path => 'list.html',
    pages => [ $page{ normal }, $page{ escaped } ],
    next => 'page-0.html',
    data => {
        tag_text => $blog->tag_text->{ foo },
    },
);

$page{ list_last } = Statocles::Page::List->new(
    app => $blog,
    path => 'list.html',
    pages => [ $page{ normal }, $page{ escaped } ],
    prev => 'page-1.html',
    data => {
        tag_text => $blog->tag_text->{ foo },
    },
);

$page{ feed } = Statocles::Page::List->new(
    app => $blog,
    author => 'Doug Bell <doug@example.com>',
    path => 'feed.rss',
    pages => $page{ list_first }->pages,
    links => {
        alternate => [
            Statocles::Link->new(
                href => $page{ list_first }->path,
                title => 'index',
            ),
        ],
    },
);

my %common_vars = (
    site => $site{ default },
    content => 'Fake content',
    app => $blog,
);

my %app_vars = (
    blog => {
        'index.html.ep' => [
            {
                %common_vars,
                self => $page{ list_first },
                page => $page{ list_first },
                pages => [ $page{ normal }, $page{ escaped } ],
            },
            {
                %common_vars,
                self => $page{ list_last },
                page => $page{ list_last },
                pages => [ $page{ normal }, $page{ escaped } ],
            },
        ],

        'index.rss.ep' => {
            %common_vars,
            self => $page{ feed },
            page => $page{ feed },
            pages => [ $page{ normal }, $page{ escaped } ],
        },
        'index.atom.ep' => {
            %common_vars,
            self => $page{ feed },
            page => $page{ feed },
            pages => [ $page{ normal }, $page{ escaped } ],
        },
        'post.html.ep' => [
            {
                %common_vars,
                self => $page{ normal },
                page => $page{ normal },
                doc => $document{ normal },
            },
            {
                %common_vars,
                self => $page{ escaped },
                page => $page{ escaped },
                doc => $document{ escaped },
            },
        ],
    },

    perldoc => {
        'pod.html.ep' => {
            %common_vars,
            self => Statocles::Page::Plain->new(
                path => '/path',
                content => 'Fake content',
                data => {
                    source_path => '/source.html',
                },
            ),
            page => Statocles::Page::Plain->new(
                path => '/path',
                content => 'Fake content',
                data => {
                    source_path => '/source.html',
                },
            ),
            content => 'Fake content',
        },
        'source.html.ep' => {
            %common_vars,
            self => Statocles::Page::Plain->new(
                path => '/path',
                content => 'Fake content',
                data => {
                    doc_path => '/source.html',
                },
            ),
            page => Statocles::Page::Plain->new(
                path => '/path',
                content => 'Fake content',
                data => {
                    doc_path => '/source.html',
                },
            ),
            content => 'Fake content',
        },
    },

    layout => {
        'default.html.ep' => [
            {
                %common_vars,
                self => $page{ normal },
                page => $page{ normal },
                app => $blog,
            },
            {
                %common_vars,
                self => $page{ escaped },
                page => $page{ escaped },
                doc => $document{ escaped },
            },
            {
                %common_vars,
                site => $site{ google_analytics },
                self => $page{ escaped },
                page => $page{ escaped },
                doc => $document{ escaped },
            },
        ],

        'full-width.html.ep' => [
            {
                %common_vars,
                self => $page{ normal },
                page => $page{ normal },
                app => $blog,
            },
            {
                %common_vars,
                self => $page{ escaped },
                page => $page{ escaped },
                doc => $document{ escaped },
            },
            {
                %common_vars,
                site => $site{ google_analytics },
                self => $page{ escaped },
                page => $page{ escaped },
                doc => $document{ escaped },
            },
        ],

        'blank.html.ep' => [
            {
                %common_vars,
                self => $page{ normal },
                page => $page{ normal },
                app => $blog,
            },
            {
                %common_vars,
                self => $page{ escaped },
                page => $page{ escaped },
                doc => $document{ escaped },
            },
            {
                %common_vars,
                site => $site{ google_analytics },
                self => $page{ escaped },
                page => $page{ escaped },
                doc => $document{ escaped },
            },
        ],
    },

    site => {
        'sitemap.xml.ep' => {
            site => $site{ default },
            pages => [ $page{ list_first }, $page{ normal }, $page{ escaped } ],
        },
        'robots.txt.ep' => {
            site => $site{ default },
        },
    },
);

# These tests are common to all layouts
sub test_layout_content {
    my ( $tmpl, $content, $dom, %args ) = @_;
    my $elem;

    subtest 'page title and site title' => sub {
        if ( ok $elem = $dom->at( 'title' ), 'title element exists' ) {
            like $elem->text, qr{@{[quotemeta $args{self}->title]}}, 'title has document title';
            like $elem->text, qr{@{[quotemeta $args{site}->title]}}, 'title has site title';
        }
    };

    subtest 'all themes must have meta generator' => sub {
        if ( ok $elem = $dom->at( 'meta[name=generator]' ), 'meta generator exists' ) {
            is $elem->attr( 'content' ), "Statocles $Statocles::VERSION",
                'generator has name and version';
        }
    };

    subtest 'author information' => sub {
        if ( my $author = $args{ page }->author ) {
            subtest 'page has author data' => sub {
                if ( ok $elem = $dom->at( 'meta[name=author]' ), 'meta author exists' ) {
                    is $elem->attr( 'content' ), $author->name, 'meta author has author name';
                }
            };
        }
        else {
            subtest 'page has no author data' => sub {
                ok !$dom->at( 'meta[name=author]' ), 'meta author does not exist';
            };
        }
    };

    subtest 'site stylesheet and script links get added' => sub {
        if ( ok $elem = $dom->at( 'link[href=/theme/css/site-style.css]', 'site stylesheet exists' ) ) {
            is $elem->attr( 'rel' ), 'stylesheet';
            is $elem->attr( 'type' ), 'text/css';
        }
        if ( ok $elem = $dom->at( 'script[src=/theme/js/site-script.js]', 'site script exists' ) ) {
            ok !$elem->text, 'no text inside';
        }
    };

    subtest 'document stylesheet links get added in the layout' => sub {
        if ( ok $elem = $dom->at( 'link[href=/theme/css/special.css]', 'document stylesheet exists' ) ) {
            is $elem->attr( 'rel' ), 'stylesheet';
            is $elem->attr( 'type' ), 'text/css';
        }
    };

    subtest 'document script links get added in the layout' => sub {
        if ( ok $elem = $dom->at( 'script[src=/theme/js/special.js]', 'document script exists' ) ) {
            ok !$elem->text, 'no text inside';
        }
    };

    subtest 'shortcut icon' => sub {
        if ( ok $elem = $dom->at( 'link[rel="shortcut icon"]', 'shortcut icon link exists' ) ) {
            is $elem->attr( 'href' ), '/favicon.ico';
        }
    };

    subtest 'google analytics' => sub {
        my $elem = $dom->find( 'script' )->grep( sub { $_->text =~ /google-analytics/ } );
        if ( my $ga_id = $args{site}->data->{google_analytics_id} ) {
            is $elem->size, 1, 'script tag with google analytics exists';
            like $elem->[0]->text, qr/\Q$ga_id/, 'GA ID is in script tag';
        }
        else {
            is $elem->size, 0, 'no script tag with google analytics exists';
        }
    };

}

# These are individual template tests to ensure basic levels of app support
# in the default themes
my %content_tests = (
    'layout/default.html.ep' => sub {
        my ( $tmpl, $content, %args ) = @_;
        my $dom = Mojo::DOM->new( $content );
        my $elem;

        test_layout_content( $tmpl, $content, $dom, %args );

        subtest 'content sections' => sub {
            ok $dom->at( '#tags-content-section' ), 'tags content section exists';
            ok $dom->at( '#feeds-content-section' ), 'feeds content section exists';
        };

    },

    'layout/full-width.html.ep' => sub {
        my ( $tmpl, $content, %args ) = @_;
        my $dom = Mojo::DOM->new( $content );
        my $elem;

        test_layout_content( $tmpl, $content, $dom, %args );
    },

    'layout/blank.html.ep' => sub {
        my ( $tmpl, $content, %args ) = @_;
        my $dom = Mojo::DOM->new( $content );
        my $elem;

        test_layout_content( $tmpl, $content, $dom, %args );
    },

    'site/sitemap.xml.ep' => sub {
        my ( $tmpl, $content, %args ) = @_;
        my $xml = Mojo::DOM->new( $content );
        my @got_loc = $xml->find( 'loc' )->map( 'text' )->each;
        cmp_deeply \@got_loc, array_each( re( qr{^http://example[.]com/} ) ), 'all pages are full urls';
    },

    'blog/index.rss.ep' => sub {
        my ( $tmpl, $content, %args ) = @_;
        my $xml = Mojo::DOM->new( $content );
        my @posts = $xml->find( 'item description' )->map( sub { Mojo::DOM->new( $_[0]->child_nodes->first->content ) } )->each;

        subtest 'all links must be full URLs' => sub {
            for my $post ( @posts ) {
                my @links = $post->find( 'a[href]' )->each;
                ok scalar @links, 'some links were found';
                for my $link ( @links ) {
                    like $link->attr( 'href' ), qr{^(?:https?:|mailto:|//)}, 'full URL';
                }
            }
        };

        subtest 'item title' => sub {
            my @titles = $xml->find( 'item title' )->each;
            is scalar @titles, scalar @{ $args{pages} }, 'right number of item titles found';
            for my $i ( 0..$#titles ) {
                my $elem = $titles[ $i ];
                like $elem->text, qr{@{[quotemeta $args{pages}[$i]->title]}}, 'title has document title';
                unlike $elem->text, qr{@{[quotemeta $args{site}->title]}}, 'title must not have site title';
            }
        };

        subtest 'item description' => sub {
            my ( $single_section, $multiple_sections )
                = $xml->find( 'item description' )
                    ->map( 'text' )
                    ->map( sub { Mojo::DOM->new( shift ) } )
                    ->each;

            subtest 'links to continue reading at section 2' => sub {
                ok !$single_section->at( 'a[href$=#section-2]' ),
                    'no link to #section-2 with single section';
                ok $multiple_sections->at( 'a[href$=#section-2]' ),
                    'link to #section-2 with multiple sections';
            };

            subtest 'tag links are shown if necessary' => sub {
                subtest 'with tags' => sub {
                    my $elem = $single_section->find( 'p' )
                        ->grep( sub { $_->text =~ /^Tags:/ } )
                        ->first;
                    ok $elem, 'tags paragraph appears when needed';
                    is $elem->find( 'a' )->size, 3, 'two tag links inside';
                    cmp_deeply [ $elem->find( 'a' )->map( 'text' )->each ],
                        [qw( foo bar <baz> )],
                        'tag link text is correct';
                    cmp_deeply [ $elem->find( 'a' )->map( attr => 'href' )->each ],
                        [qw(
                            http://example.com/blog/tag/foo
                            http://example.com/blog/tag/bar
                            http://example.com/blog/tag/baz
                        )],
                        'tag link href is correct';
                };

                subtest 'without tags' => sub {
                    ok !$multiple_sections->find( 'p' )
                        ->grep( sub { $_->text =~ /^Tags:/ } )
                        ->size,
                        'tags paragraph disappears when not needed';
                };

            };
        };
    },

    'blog/index.atom.ep' => sub {
        my ( $tmpl, $content, %args ) = @_;
        my $xml = Mojo::DOM->new( $content );

        subtest 'feed metadata' => sub {
            if ( ok my $elem = $xml->at( 'feed > author' ), 'feed has author element' ) {
                is $elem->at( 'name' )->text, $args{page}->author->name, 'feed author name correct';
            }
        };

        subtest 'feed updated' => sub {
            if ( ok my $elem = $xml->at( 'feed > updated' ), 'feed has updated element' ) {
                like $elem->text, qr{^\d{4}-\d{2}-\d{2}T\d{2}:\d{2}:\d{2}Z$}, 'date in iso8601 format';
                is $elem->text, '2015-01-02T00:00:00Z', 'date is latest of all pages';
            }
        };

        subtest 'entries' => sub {
            subtest 'author' => sub {
                my $authors = $xml->find( 'entry author' );
                is $authors->size, 2, 'right number of entry authors found';

                subtest 'author on page object' => sub {
                    my $elem = $authors->[ 0 ];
                    if ( ok $elem->at( 'name' ), 'author has name element' ) {
                        is $elem->at( 'name' )->text, $document{normal}->author->name,
                            'author name is correct';
                    }
                };

                subtest 'author on site object' => sub {
                    my $elem = $authors->[ 1 ];
                    if ( ok $elem->at( 'name' ), 'author has name element' ) {
                        is $elem->at( 'name' )->text, $args{site}->author->name,
                            'author name is correct';
                    }
                }
            };

            subtest 'title' => sub {
                my @titles = $xml->find( 'entry title' )->each;
                is scalar @titles, scalar @{ $args{pages} }, 'right number of entry titles found';
                for my $i ( 0..$#titles ) {
                    my $elem = $titles[ $i ];
                    like $elem->text, qr{@{[quotemeta $args{pages}[$i]->title]}}, 'title has document title';
                    unlike $elem->text, qr{@{[quotemeta $args{site}->title]}}, 'title must not have site title';
                }
            };

            subtest 'content' => sub {
                my ( $single_section, $multiple_sections )
                    = $xml->find( 'content' )
                        ->map( 'text' )
                        ->map( sub { Mojo::DOM->new( shift ) } )
                        ->each;

                subtest 'links to continue reading at section 2' => sub {
                    ok !$single_section->at( 'a[href$=#section-2]' ),
                        'no link to #section-2 with single section';
                    ok $multiple_sections->at( 'a[href$=#section-2]' ),
                        'link to #section-2 with multiple sections';
                };

                subtest 'tag links are shown if necessary' => sub {
                    subtest 'with tags' => sub {
                        my $elem = $single_section->find( 'p' )
                            ->grep( sub { $_->text =~ /^Tags:/ } )
                            ->first;
                        ok $elem, 'tags paragraph appears when needed';
                        is $elem->find( 'a' )->size, 3, 'two tag links inside';
                        cmp_deeply [ $elem->find( 'a' )->map( 'text' )->each ],
                            [qw( foo bar <baz> )],
                            'tag link text is correct';
                        cmp_deeply [ $elem->find( 'a' )->map( attr => 'href' )->each ],
                            [qw(
                                http://example.com/blog/tag/foo
                                http://example.com/blog/tag/bar
                                http://example.com/blog/tag/baz
                            )],
                            'tag link href is correct';
                    };

                    subtest 'without tags' => sub {
                        ok !$multiple_sections->find( 'p' )
                            ->grep( sub { $_->text =~ /^Tags:/ } )
                            ->size,
                            'tags paragraph disappears when not needed';
                    };

                };
            };
        };
    },

    'blog/index.html.ep' => sub {
        my ( $tmpl, $content, %args ) = @_;
        my $dom = Mojo::DOM->new( '<body>' . $content . '</body>' );

        subtest 'tag text exists and is processed as Markdown' => sub {
            if ( ok my $h1 = $dom->at( ':root > h1' ), 'tag text h1 exists' ) {
                is $h1->text, 'Foo!', 'h1 text is correct';
            }
            if ( ok my $p = $dom->at( ':root > p' ), 'tag text p exists' ) {
                is $p->text, 'Bar, baz, and fuzz!', 'p text is correct';
            }
        };

        subtest 'post titles' => sub {
            # Article titles should be isolated from the body by using
            # the <header> tag
            my @post_titles = $dom->find( 'article header h1' )->each;
            is scalar @post_titles, scalar @{ $args{pages} }, 'right number of post titles found (article header h1)';
            for my $i ( 0..$#post_titles ) {
                ok my $elem = $post_titles[ $i ]->at( 'a' ), "article titles must be a link to the article";
                next unless $elem;
                like $elem->text, qr{@{[quotemeta $args{pages}[$i]->title]}}, 'title has document title';
            }
        };

        subtest 'tags' => sub {
            if ( ok my $html = $args{page}->_content_sections->{tags}, 'tags content section exists' ) {
                my $dom = Mojo::DOM->new( $html );
                my $links = $dom->find( 'a' );
                cmp_deeply [ $links->map( 'text' )->each ],
                    [ '<baz>', 'bar', 'foo' ],
                    'tag text is correct and sorted';
                cmp_deeply [ $links->map( attr => 'href' )->each ],
                    [ '/blog/tag/baz/', '/blog/tag/bar/', '/blog/tag/foo/' ],
                    'tag hrefs are correct and sorted';
            }
        };

        subtest 'Older/Newer buttons' => sub {
            if ( $args{page}->prev ) {
                subtest 'Older button links to next page' => sub {
                    my $elem = $dom->at( '.next a' );
                    if ( ok $elem, 'older button exists' ) {
                        is $elem->attr( 'href' ), $args{page}->prev,
                            'older href is correct';
                    }
                };
            }
            else {
                subtest 'Older button does not link' => sub {
                    my $elem = $dom->at( '.next :first-child' );
                    if ( ok $elem, 'older button exists' ) {
                        isnt $elem->tag, 'a', 'older button is not a link';
                    }
                };
            }

            if ( $args{page}->next ) {
                subtest 'Newer button links to prev page' => sub {
                    my $elem = $dom->at( '.prev a' ) || $dom->at( '.previous a' );
                    if ( ok $elem, 'newer button exists' ) {
                        is $elem->attr( 'href' ), $args{page}->next,
                            'newer href is correct';
                    }
                };
            }
            else {
                subtest 'Newer button does not link' => sub {
                    my $elem = $dom->at( '.prev :first-child' ) || $dom->at( '.previous :first-child' );
                    if ( ok $elem, 'newer button exists' ) {
                        isnt $elem->tag, 'a', 'newer button is not a link';
                    }
                };
            }

        };
    },

    'blog/post.html.ep' => sub {
        my ( $tmpl, $content, %args ) = @_;
        my $dom = Mojo::DOM->new( $content );

        subtest 'post title' => sub {
            # Article title should be isolated from the body by using
            # the <header> tag
            ok my $elem = $dom->at( 'header h1' ), 'post title found (header h1)';
            return unless $elem;
            like $elem->text, qr{@{[quotemeta $args{self}->title]}}, 'title has document title';
        };

        subtest 'tags' => sub {
            if ( ok my $html = $args{page}->_content_sections->{tags}, 'tags content section exists' ) {
                my $dom = Mojo::DOM->new( $html );
                my $links = $dom->find( 'a' );
                cmp_deeply [ $links->map( 'text' )->each ],
                    [ '<baz>', 'bar', 'foo' ],
                    'tag text is correct and sorted';
                cmp_deeply [ $links->map( attr => 'href' )->each ],
                    [ '/blog/tag/baz/', '/blog/tag/bar/', '/blog/tag/foo/', ],
                    'tag hrefs are correct and sorted';
            }
        };
        
        subtest 'Older/Newer buttons' => sub {
            if ( $args{page}->prev ) {
                subtest 'Older button links to next page' => sub {
                    my $elem = $dom->at( '.next a' );
                    if ( ok $elem, 'older button exists' ) {
                        is $elem->attr( 'href' ), $args{page}->prev,
                        'older href is correct';
                    }
                };
            }
            else {
                subtest 'Older button does not link' => sub {
                    my $elem = $dom->at( '.next :first-child' );
                    if ( ok $elem, 'older button exists' ) {
                        isnt $elem->tag, 'a', 'older button is not a link';
                    }
                };
            }
            
            if ( $args{page}->next ) {
                subtest 'Newer button links to prev page' => sub {
                    my $elem = $dom->at( '.prev a' ) || $dom->at( '.previous a' );
                    if ( ok $elem, 'newer button exists' ) {
                        is $elem->attr( 'href' ), $args{page}->next,
                        'newer href is correct';
                    }
                };
            }
            else {
                subtest 'Newer button does not link' => sub {
                    my $elem = $dom->at( '.prev :first-child' ) || $dom->at( '.previous :first-child' );
                    if ( ok $elem, 'newer button exists' ) {
                        isnt $elem->tag, 'a', 'newer button is not a link';
                    }
                };
            }
            
        };
        

    },
);


my @theme_dirs = $THEME_DIR->children;
for my $theme_dir ( @theme_dirs ) {
    my $theme = Statocles::Theme->new(
        store => $theme_dir,
    );

    subtest $theme_dir->basename => sub {
        my $iter = $theme_dir->iterator({ recurse => 1 });
        while ( my $path = $iter->() ) {
            next unless $path->is_file;
            next unless $path->basename =~ /[.]ep$/;
            next unless $path->stat->size > 0;

            my $tmpl_path = $path->relative( $theme_dir );
            $tmpl_path =~ s/[.]ep$//;
            my $tmpl = $theme->template( $tmpl_path );

            my $name = $path->basename;
            my $app = $path->parent->basename;
            note "Testing template $app/$name";

            my $arg_sets;
            unless ( $arg_sets = $app_vars{ $app }{ $name } ) {
                diag "No test arg sets for template $app/$name";
                next;
            }
            if ( ref $arg_sets ne 'ARRAY' ) {
                $arg_sets = [ $arg_sets ];
            }

            for my $i ( 0..$#$arg_sets ) {
                my $arg_set = $arg_sets->[ $i ];
                my %args = %{ $arg_set };

                my %content_sections;
                if ( $args{page} ) {
                    %content_sections = %{ $args{page}->_content_sections };
                }

                my $content;
                lives_ok {
                    $content = $tmpl->render( %args );
                } sprintf "%s - %s (%d)", $app, $name, $i;

                my $rel_path = $path->relative( $theme_dir );
                if ( my $test = $content_tests{ $rel_path } ) {
                    subtest "content test for $rel_path ($i)"
                        => $test, $tmpl, $content, %args;
                }

                if ( $args{page} ) {
                    $args{page}->_content_sections( \%content_sections );
                }
            }
        }
    };
}

done_testing;

package Statocles;
our $VERSION = '2.000';
# ABSTRACT: A static site generator

=head1 SYNOPSIS

    # Test the site in a local web browser
    statocles daemon

    # Deploy the site
    statocles deploy

=head1 DESCRIPTION

Statocles is an application for building static web pages from a set of
plain YAML and Markdown files. It is designed to make it as simple as
possible to develop rich web content using basic text-based tools.

=head2 FEATURES

=over

=item *

A simple format based on
L<Markdown|http://daringfireball.net/projects/markdown/> for editing site
content.

=item *

A command-line application for building, deploying, and editing the site.

=item *

A simple daemon to display a test site before it goes live.

=item *

A L<blogging application|Statocles::App::Blog#FEATURES> with

=over

=item *

RSS and Atom syndication feeds.

=item *

Post-dated blog posts to appear automatically when the date is passed.

=back

=item *

Customizable L<themes|Statocles::Theme> using L<the Mojolicious template
language|Mojo::Template#SYNTAX>.

=item *

A clean default theme using L<the Skeleton CSS library|http://getskeleton.com>.

=item *

SEO-friendly features such as L<sitemaps (sitemap.xml)|http://www.sitemaps.org>.

=item *

L<Automatic checking for broken links|Statocles::Plugin::LinkCheck>.

=item *

L<Syntax highlighting|Statocles::Plugin::Highlight> for code and configuration blocks.

=back

=head1 GETTING STARTED

To get started with Statocles, L<consult the Statocles::Help guides|Statocles::Help>.

=head1 SEE ALSO

For news and documentation, L<visit the Statocles website at
http://preaction.me/statocles|http://preaction.me/statocles>.

=cut

use Mojo::Base 'Yancy';
use List::Util qw( first );
use Mojo::File qw( path );
use Mojo::JSON qw( decode_json encode_json );
use YAML qw( );
use Text::Markdown;
use Time::Piece;
use Mojo::Loader qw(load_class);

has moniker => 'statocles';
has deploy => sub { die q{"deploy" is required} };

sub startup {
    my ( $app ) = @_;

    $app->plugin( Config => {
        default => {
            title => 'My Statocles Site',
            export => {
                pages => [qw( / )],
            },
            deploy => {
                git => {
                    base_url => '',
                    branch => 'master',
                    remote => 'origin',
                },
            },
            apps => {
                blog => {
                    route => '/blog',
                },
            },
            theme => '+Statocles/theme/default',
            plugins => [
                'LinkCheck',
            ],
            data => {
                nav => [
                    {
                        href => '/',
                        text => 'Home',
                    },
                    {
                        href => '/blog',
                        text => 'Blog',
                    },
                ],
            },
        },
    } );

    $app->defaults({
        layout => $app->config->{layout} // 'default',
        template => $app->config->{template} // 'default',
    });

    # Configure deploy object
    push @{ $app->commands->namespaces }, 'Statocles::Command';
    if ( my ( $deploy_name, $deploy_conf ) = %{ $app->config->{deploy} // {} } ) {
        my $class = 'Statocles::Deploy::' . ucfirst( $deploy_name );
        if ( my $e = load_class( $class ) ) {
            die qq{Could not load class $class for deploy "$deploy_name": $e};
        }
        my $deploy = $class->new( %$deploy_conf, app => $app );
        $app->deploy( $deploy );
    }

    $app->plugin( Export => );
    push @{$app->export->pages}, '/sitemap.xml', '/robots.txt';
    # XXX AutoReload doesn't work, possibly because the fallback
    # templates provide no place to put the <script> code...
    #$app->plugin( AutoReload => );

    if ( my $theme = $app->config->{theme} ) {
        my @theme_dirs = ref $theme eq 'ARRAY' ? @{ $theme } : $theme;
        for my $theme_dir ( @theme_dirs ) {
            # Theme may be a module and path instead
            if ( $theme_dir =~ m{^\+([^/]+)/(.*)} ) {
                my ( $module, $path ) = ( $1, $2 );
                # Find the directory in the module name's "resources"
                $theme_dir =
                    first { -e }
                    map { path( $_, split( /::|'/, $module ), 'resources', $path ) }
                    @INC;
                die qq{Could not find path "resources/$path" under module $module\n\@INC contains @INC}
                    unless $theme_dir;
            }
            $app->log->debug( 'Adding theme dir: ' . $theme_dir );
            push @{$app->renderer->paths}, $theme_dir;
            push @{$app->static->paths}, $theme_dir;
        }
    }

    # Always fall back to the home dir for templates and static files to
    # allow for extra content
    push @{$app->renderer->paths}, $app->home;
    push @{$app->static->paths}, $app->home;

    # This is for absolute last-resort fallback templates
    push @{$app->renderer->classes}, __PACKAGE__;

    $app->plugin( 'Yancy', {
        backend => 'static:' . $app->home,
        read_schema => 1,
        schema => {
            pages => {
                properties => {
                    path => {
                        type => 'string',
                        'x-order' => 2,
                    },
                    title => {
                        type => 'string',
                        'x-order' => 1,
                    },
                    markdown => {
                        type => 'string',
                        format => 'markdown',
                        'x-html-field' => 'html',
                        'x-order' => 3,
                    },
                    html => {
                        type => 'string',
                    },
                    template => {
                        type => [ 'string', 'null' ],
                        default => 'default',
                    },
                    layout => {
                        type => [ 'string', 'null' ],
                        default => 'default',
                    },
                    status => {
                        type => 'string',
                        enum => [qw( published draft )],
                        default => 'published',
                    },
                    date => {
                        type => [ 'string', 'null' ],
                        format => 'datetime',
                    },
                    data => {
                    },
                    # XXX Add other fields
                    # tags
                    # - Array of strings or comma-separated strings
                    # search_change_frequency
                    # - always hourly daily weekly monthly yearly never
                    # search_priority
                    # - Number between 0.0 and 1.0
                    # last_modified
                    # - Datetime
                },
            },
        },
    } );

    $app->helper( strftime => \&_helper_strftime );
    $app->helper( sectionize => sub {
        my ( $c, $html ) = @_;
        return [ split m{\n*<hr\s*/?>\n*}, $html ];
    } );
    $app->helper( url_for => sub {
        # Replace the Mojolicious url_for helper to remove the trailing
        # `index` that will automatically be added by the fallback route
        # when looking up the page
        my $url = Mojolicious::Controller::url_for( @_ );
        $url->path( $url->path =~ s{/index(\#|\Z)}{/$1}r );
        return $url;
    } );

    # Add configured plugins
    push @{$app->plugins->namespaces}, 'Statocles::Plugin';
    for my $plugin ( @{ $app->config->{plugins} || [] } ) {
        $app->plugin( ref $plugin ? @$plugin : $plugin );
    }

    # Add routes to see content
    my $r = $app->routes;

    # Add default robots.txt and sitemap.xml
    $r->get( '/sitemap' )->to( 'yancy#list', schema => 'pages', template => 'sitemap' );

    # Add configured app routes
    my %apps;
    for my $moniker ( sort keys %{ $app->config->{apps} } ) {
        my $conf = $app->config->{apps}{ $moniker };
        my $class = 'Statocles::App::' . ucfirst( $conf->{app} || $moniker );
        if ( my $e = load_class( $class ) ) {
            die "Could not load class $class for app $moniker: $e";
        }
        my $site_app = $class->new( moniker => $moniker, %$conf );
        $site_app->register( $app, $conf );
        $apps{ $moniker } = $site_app;
    }
    $app->helper( 'statocles.app' => sub {
        my ( $c, $moniker ) = @_;
        return $apps{ $moniker };
    } );

    # Fallback route to read pages
    $r->get( '/*id', { id => 'index' }, sub {
        my ( $c ) = @_;
        my $id = $c->stash( 'id' );
        if ( my $page = $c->yancy->get( pages => $id ) ) {
            return $c->render(
                item => $page,
                ( template => $page->{template} )x!!$page->{template},
                ( layout => $page->{layout} )x!!$page->{layout},
                title => $page->{title},
            );
        }
        if ( $id !~ m{/$} && -d $c->app->home->child( $id ) ) {
            return $c->redirect_to( "/$id/" );
        }
        if ( my ( $format ) = $id =~ m{/[^/]+[.]([^./]+)$} ) {
            $c->stash( format => $format );
            $id =~ s{[.]$format$}{};
        }
        return if $c->render_maybe( $id );
        # Allow an 'index' template in the same directory as the
        # requested resource to handle this request
        $id =~ s{(^|/)[^/]+$}{${1}index};
        $c->render( $id );
    } );
}

sub _helper_strftime {
    my ( $c, $format, $date ) = @_;
    my $dt;
    if ( $date ) {
        $dt = Time::Piece->strptime( $date, '%Y-%m-%d %H:%M:%S' );
    }
    else {
        $dt = Time::Piece->new;
    }
    return $dt->strftime( $format );
}

1;
__DATA__
@@ layouts/default.html.ep
<!DOCTYPE html>
<head>
    <title><%= title %></title>
    %= content 'head'
</head>
<body>
    <header>
        %= content header => begin
        <nav>
            %= content 'navbar'
        </nav>
        %= content 'hero'
        % end
    </header>
    %= content container => begin
    <div style="display: flex">
        <div style="flex: 1 1 80%">
            <main>
                %= content main => begin
                    %= content
                % end
            </main>
        </div>
        <div style="flex: 1 1 20%">
            %= content sidebar => begin
                % my $app = app->statocles->app( 'blog' );
                % if ( $app && ( my @links = $app->category_links ) ) {
                    <h1>Categories</h1>
                    % for my $link ( @links ) {
                        %= link_to $link->{title}, $link->{href}
                    % }
                % }
            % end
        </div>
    </div>
    % end
    <footer>
        %= content 'footer'
    </footer>
</body>

@@ default.html.ep
%= content 'content_before'
<header>
    <h1><%= $item->{title} %></h1>
    % if ( $item->{date} ) {
    <aside>
        <time datetime="<%= strftime('%Y-%m-%d', $item->{date} ) %>">
            Posted on <%= strftime('%Y-%m-%d', $item->{date} ) %>
        </time>
    </aside>
    % }
    % if ( $item->{author} ) {
    <aside>
        %= content author => begin
        <span class="author">by <%= $item->{author} %></span>
        % end
    </aside>
    % }
</header>
% my $sections = sectionize( $item->{html} );
% for my $i ( 0 .. $#$sections ) {
    <section id="section-<%= $i + 1 %>"><%== $sections->[ $i ] %></section>
% }
%= content 'content_after'

@@ sitemap.xml.ep
<?xml version="1.0" encoding="UTF-8" ?>
<urlset xmlns="http://www.sitemaps.org/schemas/sitemap/0.9">
% for my $item ( @$items ) {
    <url>
        <loc><%= url_for( $item->{path} )->to_abs %></loc>
        <changefreq><%= $item->{search_change_frequency} // 'weekly' %></changefreq>
        <priority><%= $item->{search_priority} // 0.5 %></priority>
        <lastmod><%= strftime( '%Y-%m-%d', $item->{last_modified} // $item->{date} ) %></lastmod>
    </url>
% }
</urlset>

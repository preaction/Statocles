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

sub startup {
    my ( $app ) = @_;

    $app->defaults({ layout => 'default' });

    $app->plugin( Config => {
        default => {
            title => 'My Statocles Site',
            export => {
                pages => [qw( / )],
            },
            deploy => {
                base_url => '',
                branch => 'deploy',
                remote => '',
            },
            apps => {
                blog => {
                    route => '/',
                },
            },
            theme => '+Statocles/theme/default',
            plugins => [
                'LinkCheck',
            ],
            data => {
                main_nav => [
                ],
            },
        },
    } );

    $app->plugin( Export => );
    push @{$app->export->pages}, '/sitemap.xml', '/robots.txt';
    #$app->plugin( AutoReload => );

    # This is for absolute last-resort fallback templates
    push @{$app->renderer->classes}, __PACKAGE__;

    if ( my $theme_dir = $app->config->{theme} ) {
        # Theme may be a module and path instead
        if ( $theme_dir =~ m{\+([^/]+)/(.*)} ) {
            my ( $module, $path ) = ( $1, $2 );
            # Find the directory in the module name's "resources"
            $theme_dir =
                first { -e path( $_, split( /::|'/, $module ), 'resources', $path ) }
                @INC;
            die qq{Could not find path "resources/$path" under module $module\n\@INC contains @INC}
                unless $theme_dir;
        }
        push @{$app->renderer->paths}, $theme_dir;
        push @{$app->static->paths}, $theme_dir;
    }

    # Always fall back to the home dir for templates and static files to
    # allow for extra content
    push @{$app->renderer->paths}, $app->home;
    push @{$app->static->paths}, $app->home;

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
                    # search_change_frequency
                    # always hourly daily weekly monthly yearly never
                    # search_priority
                    # Number between 0.0 and 1.0
                    # last_modified
                },
            },
        },
    } );

    $app->helper( strftime => sub {
        my ( $c, $format, $date ) = @_;
        my $dt;
        if ( $date ) {
            $dt = Time::Piece->strptime( $date, '%Y-%m-%d %H:%M:%S' );
        }
        else {
            $dt = Time::Piece->new;
        }
        return $dt->strftime( $format );
    } );

    $app->helper( section => sub {
        my ( $c, $no, $html ) = @_;
        my $dom = Mojo::DOM->new( $html );
        if ( my $end = $dom->at( ":root > hr:nth-of-type( $no )" ) ) {
            $end->following->each( 'delete' );
        }
        return "$dom";
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
    for my $moniker ( sort keys %{ $app->config->{apps} } ) {
        my $conf = $app->config->{apps}{ $moniker };
        my $class = 'Statocles::App::' . ucfirst( $conf->{app} || $moniker );
        if ( my $e = load_class( $class ) ) {
            die "Could not load class $class for app $moniker: $e";
        }
        my $site_app = $class->new( %$conf );
        $site_app->register( $app, $conf );
    }

    # Fallback route to read pages
    $r->get( '/*id', { id => 'index' }, sub {
        my ( $c ) = @_;
        my $id = $c->stash( 'id' );
        if ( my $page = $c->yancy->get( pages => $id ) ) {
            return $c->render(
                content => $page->{html},
                template => $page->{template} || 'default',
                layout => $page->{layout} || 'default',
                title => $page->{title},
                page => $page,
            );
        }
        if ( my ( $format ) = $id =~ m{/[^/]+[.]([^./]+)$} ) {
            $c->stash( format => $format );
            $id =~ s{[.]$format$}{};
        }
        return if $c->render_maybe( $id );
        $id =~ s{(^|/)[^/]+$}{${1}index};
        $c->render( $id );
    } );
}

1;
__DATA__
@@ layouts/default.html.ep
<!DOCTYPE html>
<head>
    <title><%= title %></title>
</head>
<body>
    %= content
</body>
@@ default.html.ep
%== stash 'content'
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

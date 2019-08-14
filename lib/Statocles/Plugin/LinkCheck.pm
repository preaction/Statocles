package Statocles::Plugin::LinkCheck;
our $VERSION = '0.095';
# ABSTRACT: Check links and images for validity during build

use Statocles::Base 'Class';
with 'Statocles::Plugin';
use Mojo::Util qw( url_escape url_unescape );

=attr ignore

An array of URL patterns to ignore. These are interpreted as regular expressions,
and are anchored to the beginning of the URL.

For example:

    /broken     will match "/broken.html" "/broken/page.html" but not "/page/broken"
    .*/broken   will match "/broken.html" "/broken/page.html" and "/page/broken"

=cut

has ignore => (
    is => 'ro',
    isa => ArrayRef[Str],
    default => sub { [] },
);

=method check_pages

    $plugin->check_pages( $event );

Check the pages inside the given
L<Statocles::Event::Pages|Statocles::Event::Pages> event.

=cut

sub check_pages {
    my ( $self, $event ) = @_;

    my %page_paths = ();
    my %links = ();
    my %empty = (); # Pages with empty links
    for my $page ( @{ $event->pages } ) {
        $page_paths{ url_unescape $page->path } = 1;
        if ( $page->DOES( 'Statocles::Page::Document' ) ) {
            my $dom = $page->dom;

            for my $attr ( qw( src href ) ) {
                for my $el ( $dom->find( "[$attr]" )->each ) {
                    my $url = $el->attr( $attr );

                    if ( !$url ) {
                        push @{ $empty{ $page->path } }, $el;
                    }

                    $url =~ s{#.*$}{};
                    next unless $url; # Skip checking fragment-internal links for now
                    next if $url =~ m{^(?:[a-z][a-z0-9+.-]*):}i;
                    next if $url =~ m{^//};
                    if ( $url !~ m{^/} ) {
                        my $clone = $page->path->clone;
                        pop @$clone;
                        $url = join '/', $clone, $url;
                    }

                    # Fix ".." and ".". Path::Tiny->canonpath can't do
                    # this for us because these paths do not exist on
                    # the filesystem
                    $url =~ s{/[^/]+/[.][.]/}{/}g; # Fix ".." to refer to parent
                    $url =~ s{/[.]/}{/}g; # Fix "." to refer to self

                    $links{ url_unescape $url }{ url_unescape $page->path }++;

                }
            }
        }
    }

    my @missing; # Array of arrayrefs of [ link_url, page_path ]
    for my $link_url ( keys %links ) {
        $link_url .= 'index.html' if $link_url =~ m{/$};
        next if $page_paths{ $link_url } || $page_paths{ "$link_url/index.html" };
        next if grep { $link_url =~ /^$_/ } @{ $self->ignore };
        push @missing, [ $link_url, $_ ] for keys %{ $links{ $link_url } };
    }

    for my $page_url ( keys %empty ) {
        push @missing, map { [ '', $page_url, $_ ] } @{ $empty{ $page_url } };
    }

    if ( @missing ) {
        # Sort by page url and then missing link url
        for my $m ( sort { $a->[1] cmp $b->[1] || $a->[0] cmp $b->[0] } @missing ) {
            my $msg = $m->[0] ? sprintf( q{'%s' not found}, $m->[0] )
                    : sprintf( q{Link with text "%s" has no destination}, $m->[2]->text )
                    ;
            $event->emitter->log->warn( "URL broken on $m->[1]: $msg" );
        }
    }
}

=method register

Register this plugin to install its event handlers. Called automatically.

=cut

sub register {
    my ( $self, $site ) = @_;
    $site->on( build => sub { $self->check_pages( @_ ) } );
}

1;

=head1 SYNOPSIS

    # site.yml
    site:
        class: Statocles::Site
        args:
            plugins:
                link_check:
                    $class: Statocles::Plugin::LinkCheck

=head1 DESCRIPTION

This plugin checks all of the links and images to ensure they exist. If something
is missing, this plugin will write a warning to the screen.


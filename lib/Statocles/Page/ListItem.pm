package Statocles::Page::ListItem;
our $VERSION = '0.082';
# ABSTRACT: An item in a List page

use Statocles::Base 'Class';
use Mojo::DOM;

=attr page

The L<page object|Statocles::Page> for this item in the list.

=cut

has page => (
    is => 'ro',
    isa => ConsumerOf[ 'Statocles::Page' ],
);

=attr rewrite_mode

One of "absolute" or "full". Defaults to "absolute".

If "absolute", will rewrite the content using the absolute path of the page.

If "full", will use the full URL (the site base_url and the page URL) when 
rewriting the content.

=cut

has rewrite_mode => (
    is => 'ro',
    isa => Enum[qw( absolute full )],
    default => 'absolute',
);

=method DOES

This page proxies everything necessary to be a page object, without consuming
the L<page role|Statocles::Page>.

=cut

sub DOES {
    my ( $self, $class ) = @_;
    return $self->page->DOES( $class );
}

=method AUTOLOAD

Methods are proxyed to the L<page object|/page> so that this object appears
mostly as the page inside of it.

=cut

our $AUTOLOAD;
sub AUTOLOAD {
    my ( $self, @args ) = @_;
    my ( $method_name ) = $AUTOLOAD =~ /::([^:]+)$/;

    # We must be able to destroy ourselves
    # This issue is fixed in perl 5.18
    return if $method_name eq 'DESTROY';

    my $method = $self->page->can( $method_name );
    if ( !$method ) {
        die sprintf q{ListItem page (%s %s) has no method "%s"},
            $self->page->path,
            ref $self->page,
            $method_name;
    }
    return $method->( $self->page, @args );
}

=method content

    my $html = $page->content;

Get the content for this page. Rewrite any links, images, or other according to the
L<rewrite_mode attributes|/rewrite_mode>.

=cut

sub _rewrite_content {
    my ( $self, $content ) = @_;

    my $dom = Mojo::DOM->new( $content );
    for my $attr ( qw( src href ) ) {
        for my $el ( $dom->find( "[$attr]" )->each ) {
            my $url = $el->attr( $attr );

            # relative URLs must be absolute
            if ( $url !~ m{^(?:(?:[a-zA-Z]+:)|//?)} ) {
                $url = $self->page->dirname . '/' . $url;
            }

            # absolute URLs may be full
            if ( $self->rewrite_mode eq 'full' ) {
                if ( $url !~ m{^(?:(?:[a-zA-Z]+:)|//)} ) {
                    $url = $self->page->site->url( $url );
                }
            }

            $el->attr( $attr => $url );
        }
    }

    return "$dom";
}

sub content {
    my ( $self, @args ) = @_;
    my $content = $self->page->content( @args );
    return $self->_rewrite_content( $content );
}

=method sections

    my @sections = $page->sections;

Get a list of content divided into sections. The Markdown "---" marker divides
sections. Rewrite any links, images, or other according to the L<rewrite_mode
attributes|/rewrite_mode>.

=cut

sub sections {
    my ( $self, @args ) = @_;
    return map { $self->_rewrite_content( $_ ) } $self->page->sections( @args );
}

1;
__END__

=head1 DESCRIPTION

This page wraps another page for use inside of a L<list
page|Statocles::Page::List>.  This page will rewrite content to ensure that
relative links in the page work correctly when moved into the list page.


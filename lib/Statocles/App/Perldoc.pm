package Statocles::App::Perldoc;
# ABSTRACT: Render documentation for Perl modules

use Statocles::Class;
use Statocles::Theme;
use Statocles::Page::Raw;
use Pod::Simple::Search;
use Pod::Simple::XHTML;

=attr url_root

The URL root of this application. All pages from this app will be under this
root. Use this to ensure two apps do not try to write the same path.

=cut

has url_root => (
    is => 'ro',
    isa => Str,
    required => 1,
);

=attr theme

The L<theme|Statocles::Theme> for this app. See L</THEME> for what templates this app
uses.

=cut

has theme => (
    is => 'ro',
    isa => InstanceOf['Statocles::Theme'],
    required => 1,
    coerce => Statocles::Theme->coercion,
);

=attr inc

The directories to search for modules. Defaults to @INC.

=cut

has inc => (
    is => 'ro',
    isa => ArrayRef[Path],
    # We can't check for existence, because @INC might contain nonexistent
    # directories (I think)
    default => sub { [ map { Path::Tiny->new( $_ ) } @INC ] },
);

=attr modules

The root modules to find. Required. All child modules will be included. Any module that does
not start with one of these strings will not be included.

=cut

has modules => (
    is => 'ro',
    isa => ArrayRef[Str],
    required => 1,
);

=attr index_module

The module to use for the index page. Required.

=cut

has index_module => (
    is => 'ro',
    isa => Str,
    required => 1,
);

=method pages

Render the requested modules as HTML.

=cut

sub pages {
    my ( $self ) = @_;
    my @dirs = map { "$_" } @{ $self->inc };
    my $pod_base = 'https://metacpan.org/pod/';

    my %modules;
    for my $glob ( @{ $self->modules } ) {
        %modules = (
            %modules,
            %{ Pod::Simple::Search->new->inc(0)->limit_glob( $glob )->survey( @dirs ) },
        );
    }

    #; use Data::Dumper;
    #; say Dumper \%modules;

    my @pages;
    for my $module ( keys %modules ) {

        my $path = $modules{ $module };
        #; use Data::Dumper;
        #; say Dumper $path;

        my $parser = Pod::Simple::XHTML->new;
        $parser->perldoc_url_prefix( $pod_base );
        $parser->$_('') for qw( html_header html_footer );
        $parser->output_string( \(my $parser_output) );
        $parser->parse_file( "$path" );
        #; say $parser_output;

        # Rewrite links for modules that we will be serving locally
        my $dom = Mojo::DOM->new( $parser_output );
        for my $node ( $dom->find( 'a[href]' )->each ) {
            my $href = $node->attr( 'href' );
            $href =~ s/$pod_base//;

            if ( grep { $href =~ /^$_/ } @{ $self->modules } ) {
                $href = join '/', split /::/, $href;
                $href .= '.html';
                $node->attr( href => join '/', $self->url_root, $href );
            }
        }

        my $page_url = $module eq $self->index_module ? 'index.html' : $path;
        $page_url =~ s/[.]pm$/.html/;

        push @pages, Statocles::Page::Raw->new(
            path => join( '/', $self->url_root, $page_url ),
            layout => $self->theme->template( site => 'layout.html' ),
            template => $self->theme->template( perldoc => 'pod.html' ),
            content => "$dom",
        );

    }

    return @pages;
}

1;
__END__

=head1 DESCRIPTION

This application generates HTML from the POD in the requested modules.

=cut


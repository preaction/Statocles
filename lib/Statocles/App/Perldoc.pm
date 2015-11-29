package Statocles::App::Perldoc;
# ABSTRACT: Render documentation for Perl modules

use Statocles::Base 'Class';
use Statocles::Page::Plain;
use Scalar::Util qw( blessed );
use Pod::Simple::Search;
use Pod::Simple::XHTML;
with 'Statocles::App';

=attr inc

The directories to search for modules. Defaults to @INC.

=cut

has inc => (
    is => 'ro',
    isa => ArrayRef[Path],
    # We can't check for existence, because @INC might contain nonexistent
    # directories (I think)
    default => sub { [ @INC ] },
    coerce => sub {
        my ( $args ) = @_;
        return [ map { Path::Tiny->new( $_ ) } @$args ];
    },
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

=attr weave

If true, run the POD through L<Pod::Weaver> before converting to HTML

=cut

has weave => (
    is => 'ro',
    isa => Bool,
    default => sub { 0 },
);

=attr weave_config

The path to the Pod::Weaver configuration file

=cut

has weave_config => (
    is => 'ro',
    isa => Path,
    default => sub { './weaver.ini' },
    coerce => Path->coercion,
);

=method pages

    my @pages = $app->pages;

Render the requested modules as HTML. Returns an array of L<Statocles::Page> objects.

=cut

sub pages {
    my ( $self ) = @_;
    my @dirs = map { "$_" } @{ $self->inc };
    my $pod_base = 'https://metacpan.org/pod/';

    my %modules;
    for my $glob ( @{ $self->modules } ) {
        %modules = (
            %modules,
            %{ Pod::Simple::Search->new->inc(0)->limit_re( qr{^$glob} )->survey( @dirs ) },
        );

        # Also check for exact matches, for strange extensions
        for my $dir ( @dirs ) {
            my @glob_parts = split /::/, $glob;
            my $path = Path::Tiny->new( $dir, @glob_parts );
            if ( $path->is_file ) {
                $modules{ $glob } = "$path";
            }
        }
    }


    #; use Data::Dumper;
    #; say Dumper \%modules;

    my @pages;
    for my $module ( keys %modules ) {

        my $path = $modules{ $module };
        #; use Data::Dumper;
        #; say Dumper $path;

        # Weave the POD before trying to make HTML
        my $pod = $self->weave
                ? $self->_weave_module( $path )
                : Path::Tiny->new( $path )->slurp
                ;

        my $parser = Pod::Simple::XHTML->new;
        $parser->perldoc_url_prefix( $pod_base );
        $parser->$_('') for qw( html_header html_footer );
        $parser->output_string( \(my $parser_output) );
        $parser->parse_string_document( $pod );
        #; say $parser_output;

        my $dom = Mojo::DOM->new( $parser_output );
        for my $node ( $dom->find( 'a[href]' )->each ) {
            my $href = $node->attr( 'href' );

            # Rewrite links for modules that we will be serving locally
            if ( grep { $href =~ /^$pod_base$_/ } @{ $self->modules } ) {
                my ( $module, $section ) = $href =~ /^$pod_base([^#]+)(?:\#(.*))?$/;
                my $url = $self->url( $self->_module_href( $module ) );
                $node->attr( href => $section ? join( "#", $url, $section ) : $url );
            }
            # Add rel="external" for remaining external links
            elsif ( $href =~ m{(?:[^:]+:)?//} ) {
                $node->attr( rel => 'external' );
            }

        }

        my $source_path = "$module/source.html";
        $source_path =~ s{::}{/}g;

        my ( @parts ) = split m{::}, $module;
        my @crumbtrail;
        for my $i ( 0..$#parts ) {
            my $trail_module = join "::", @parts[0..$i];
            if ( $modules{ $trail_module } ) {
                push @crumbtrail, {
                    text => $parts[ $i ],
                    href => $self->url( $self->_module_href( $trail_module ) ),
                };
            }
            else {
                push @crumbtrail, {
                    text => $parts[ $i ],
                };
            }
        }

        my %page_args = (
            layout => $self->site->theme->template( site => 'layout.html' ),
            template => $self->site->theme->template( perldoc => 'pod.html' ),
            title => $module,
            content => "$dom",
            app => $self,
            path => $self->_module_href( $module ),
            data => {
                source_path => $self->url( $source_path ),
                crumbtrail => \@crumbtrail,
            },
        );

        if ( $module eq $self->index_module ) {
            unshift @pages, Statocles::Page::Plain->new( %page_args );
        }
        else {
            push @pages, Statocles::Page::Plain->new( %page_args );
        }

        # Add the source as a text file
        push @pages, Statocles::Page::Plain->new(
            path => $source_path,
            layout => $self->site->theme->template( site => 'layout.html' ),
            template => $self->site->theme->template( perldoc => 'source.html' ),
            title => "$module (source)",
            content => Path::Tiny->new( $path )->slurp,
            app => $self,
            data => {
                doc_path => $self->url( $page_args{path} ),
                crumbtrail => \@crumbtrail,
            },
        );

    }

    return @pages;
}

sub _module_href {
    my ( $self, $module ) = @_;
    if ( $module eq $self->index_module ) {
        return '/index.html';
    }

    my $page_url = "$module/index.html";
    $page_url =~ s{::}{/}g;
    return $page_url;
}

# Run Pod::Weaver on the POD in the given path
sub _weave_module {
    my ( $self, $path ) = @_;

    # Oh... My... GOD...
    my @missing;
    eval { require Pod::Weaver; 1; } or push @missing, 'Pod::Weaver';
    eval { require PPI; 1; } or push @missing, 'PPI';
    eval { require Pod::Elemental; 1; } or push @missing, 'Pod::Elemental';
    eval { require Encode; 1; } or push @missing, 'Encode';
    if ( @missing ) {
        die "Cannot weave POD: Missing modules " . join( " ", @missing );
    }

    my $perl_utf8 = Encode::encode( 'utf-8', Path::Tiny->new( $path )->slurp, Encode::FB_CROAK );
    my $ppi_document = PPI::Document->new( \$perl_utf8 ) or die PPI::Document->errstr;

    ### Copy/paste from Pod::Elemental::PerlMunger
    my $code_elems = $ppi_document->find(
        sub {
            return
                if grep { $_[ 1 ]->isa( "PPI::Token::$_" ) }
                qw(Comment Pod Whitespace Separator Data End);
            return 1;
        }
    );

    $code_elems ||= [];
    my @pod_tokens;

    my @queue = $ppi_document->children;
    while ( my $element = shift @queue ) {
        if ( $element->isa( 'PPI::Token::Pod' ) ) {
            # save the text for use in building the Pod-only document
            push @pod_tokens, "$element";
        }

        if ( blessed $element && $element->isa( 'PPI::Node' ) ) {
            # Depth-first keeps the queue size down
            unshift @queue, $element->children;
        }
    }

    ## Check for any problems, like POD inside of heredoc or strings
    my $finder = sub {
        my $node = $_[ 1 ];
        return 0
            unless grep { $node->isa( $_ ) }
        qw( PPI::Token::Quote PPI::Token::QuoteLike PPI::Token::HereDoc );
        return 1 if $node->content =~ /^=[a-z]/m;
        return 0;
    };

    if ( $ppi_document->find_first( $finder ) ) {
        warn "can't invoke Pod::Weaver on '$path': There is POD in string literals";
        return '';
    }

    my $pod_str = join "\n", @pod_tokens;
    my $pod_document = Pod::Elemental->read_string( $pod_str );

    ### MUNGE THE POD HERE!

    my $weaver = Pod::Weaver->new_from_config(
        { root => $self->weave_config->parent->stringify },
    );
    my $weaved_doc = $weaver->weave_document({
        pod_document => $pod_document,
        ppi_document => $ppi_document,
    });

    ### END MUNGE THE POD

    my $pod_text = $weaved_doc->as_pod_string;

    #; say $pod_text;
    return $pod_text;
}

1;
__END__

=head1 DESCRIPTION

This application generates HTML from the POD in the requested modules.

=cut


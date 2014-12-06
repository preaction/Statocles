package Statocles::App::Perldoc;
# ABSTRACT: Render documentation for Perl modules

use Statocles::Class;
use Statocles::Theme;
use Statocles::Page::Raw;
use Scalar::Util qw( blessed );
use List::MoreUtils qw( any );
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

        # Weave the POD before trying to make HTML
        my $pod = $self->weave( $path );

        my $parser = Pod::Simple::XHTML->new;
        $parser->perldoc_url_prefix( $pod_base );
        $parser->$_('') for qw( html_header html_footer );
        $parser->output_string( \(my $parser_output) );
        $parser->parse_string_document( $pod );
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

=method weave

If desired, run Pod::Weaver on the POD before creating HTML.

=cut

sub weave {
    my ( $self, $path ) = @_;

    # Oh... My... GOD...
    require PPI;
    require Pod::Elemental;
    require Encode;
    my $perl_utf8 = Encode::encode( 'utf-8', Path::Tiny->new( $path )->slurp, Encode::FB_CROAK );
    my $ppi_document = PPI::Document->new( \$perl_utf8 ) or die PPI::Document->errstr;

    ### Copy/paste from Pod::Elemental::PerlMunger
    my $last_code_elem;
    my $code_elems = $ppi_document->find(
        sub {
            return
                if grep { $_[ 1 ]->isa( "PPI::Token::$_" ) }
                qw(Comment Pod Whitespace Separator Data End);
            return 1;
        }
    );

    $code_elems ||= [];
    for my $elem ( @$code_elems ) {
        # Really, we might get two elements on the same line, and one could be
        # later in position because it could have a later column — but we don't
        # care, because we're only thinking about Pod, which is linewise.
        next
            if $last_code_elem
            and $elem->line_number <= $last_code_elem->line_number;

        $last_code_elem = $elem;
    }

    my @pod_tokens;

    {
        my @queue = $ppi_document->children;
        while ( my $element = shift @queue ) {
            if ( $element->isa( 'PPI::Token::Pod' ) ) {
                my $after_last = $last_code_elem
                    && $last_code_elem->line_number > $element->line_number;

                # save the text for use in building the Pod-only document
                push @pod_tokens, "$element";

                # Replace with nothing
                $element->delete;

                next;
            }

            if ( blessed $element && $element->isa( 'PPI::Node' ) ) {
                # Depth-first keeps the queue size down
                unshift @queue, $element->children;
            }
        }
    }

    my $finder = sub {
        my $node = $_[ 1 ];
        return 0
            unless any { $node->isa( $_ ) }
        qw( PPI::Token::Quote PPI::Token::QuoteLike PPI::Token::HereDoc );
        return 1 if $node->content =~ /^=[a-z]/m;
        return 0;
    };

    if ( $ppi_document->find_first( $finder ) ) {
        warn
            sprintf "can't invoke %s on %s: there is POD inside string literals",
            $self->plugin_name,
            $path;
    }

    my $pod_str = join "\n", @pod_tokens;
    my $pod_document = Pod::Elemental->read_string( $pod_str );

    ### MUNGE THE POD HERE!

    require Pod::Weaver;
    my $weaver = Pod::Weaver->new_from_config(
        { root => '.' },
    );
    my $weaved_doc = $weaver->weave_document({
        pod_document => $pod_document,
        ppi_document => $ppi_document,
    });

    ### END MUNGE THE POD

    my $new_pod = $weaved_doc->as_pod_string;

    my $end_finder = sub {
        return 1
            if $_[ 1 ]->isa( 'PPI::Statement::End' )
            || $_[ 1 ]->isa( 'PPI::Statement::Data' );
        return 0;
    };

    my $end = do {
        my $end_elem = $ppi_document->find( $end_finder );

        # If there's nothing after __END__, we can put the POD there:
        if (
            not $end_elem
            or (    @$end_elem == 1
                and $end_elem->[ 0 ]->isa( 'PPI::Statement::End' )
                and $end_elem->[ 0 ] =~ /^__END__\s*\z/ )
            )
        {
            $end_elem = [];
        }

        @$end_elem ? join q{}, @$end_elem : undef;
    };

    $ppi_document->prune( $end_finder );

    my $new_perl =
        Encode::decode( 'utf-8', $ppi_document->serialize, Encode::FB_CROAK, );

    s/\n\s*\z// for $new_perl, $new_pod;

    my $pod_text = defined $end
        ? "$new_perl\n\n$new_pod\n\n$end"
        : "$new_perl\n\n__END__\n\n$new_pod\n";
    ### End copy/paste from Pod::Elemental::PerlMunger

    #; say $pod_text;
    return $pod_text;
}

1;
__END__

=head1 DESCRIPTION

This application generates HTML from the POD in the requested modules.

=cut


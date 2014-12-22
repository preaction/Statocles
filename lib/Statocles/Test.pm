package Statocles::Test;
# ABSTRACT: Common test routines for Statocles

use Statocles::Base;
use Test::More;
use Test::Exception;
use Test::Deep;
use base qw( Exporter );
our @EXPORT_OK = qw( test_constructor test_pages );

=sub test_constructor( class, args )

Test an object constructor. C<class> is the class to test. C<args> is a list of
name/value pairs with the following keys:

=over 4

=item required

A set of name/value pairs for required arguments. These will be tested to ensure they
are required. They will be added to every attempt to construct an object.

=item default

A set of name/value pairs for default arguments. These will be tested to ensure they
are set to the correct defaults.

=back

=cut

sub test_constructor {
    my ( $class, %args ) = @_;

    my %required = $args{required} ? ( %{ $args{required} } ) : ();
    my %defaults = $args{default} ? ( %{ $args{default} } ) : ();

    local $Test::Builder::Level = $Test::Builder::Level + 1;

    subtest $class . ' constructor' => sub {
        isa_ok $class->new( %required ), $class,
            'constructor works with all required args';

        if ( $args{required} ) {
            subtest 'required attributes' => sub {
                for my $key ( keys %required ) {
                    dies_ok {
                        $class->new(
                            map {; $_ => $required{ $_ } } grep { $_ ne $key } keys %required,
                        );
                    } $key . ' is required';
                }
            };
        }

        if ( $args{default} ) {
            subtest 'attribute defaults' => sub {
                my $obj = $class->new( %required );
                for my $key ( keys %defaults ) {
                    if ( ref $defaults{ $key } eq 'CODE' ) {
                        local $_ = $obj->$key;
                        subtest "$key default value" => $defaults{ $key };
                    }
                    else {
                        cmp_deeply $obj->$key, $defaults{ $key }, "$key default value";
                    }
                }
            };
        }

    };
}

=sub test_pages( site, app, tests )

Test the pages of the given app. C<tests> is a set of pairs of C<path> => C<callback>
to test the pages returned by the app.

The C<callback> will be given two arguments:

=over

=item C<output>

The output of the rendered page.

=item C<dom>

If the page is HTML, a L<Mojo::DOM> object ready for testing.

=back

=cut

sub test_pages {
    my ( $site, $app ) = ( shift, shift );

    my %opt;
    if ( ref $_[0] eq 'HASH' ) {
        %opt = %{ +shift };
    }

    my ( $index_path, $index_test, %page_tests ) = @_;
    $page_tests{ $index_path } = $index_test;

    local $Test::Builder::Level = $Test::Builder::Level + 1;

    my @warnings;
    local $SIG{__WARN__} = sub { push @warnings, $_[0] };

    my @pages = $app->pages;

    is scalar @pages, scalar keys %page_tests, 'correct number of pages';

    if ( !$opt{noindex} ) {
        is $pages[0]->path, $index_path, 'index page must come first';
    }

    for my $page ( @pages ) {
        ok $page->DOES( 'Statocles::Page' ), 'must be a Statocles::Page';

        if ( !$page->isa( 'Statocles::Page::Feed' ) ) {
            isa_ok $page->last_modified, 'Time::Piece', 'must set a last_modified';
        }

        if ( !$page_tests{ $page->path } ) {
            fail "No tests found for page: " . $page->path;
            next;
        }

        my $output = $page->render( site => $site );
        # Handle filehandles from render
        if ( ref $output eq 'GLOB' ) {
            $output = do { local $/; <$output> };
        }

        if ( $page->path =~ /[.](?:html|rss|atom)$/ ) {
            my $dom = Mojo::DOM->new( $output );
            fail "Could not parse dom" unless $dom;
            subtest 'html content: ' . $page->path, $page_tests{ $page->path }, $output, $dom;
        }
        elsif ( $page_tests{ $page->path } ) {
            subtest 'text content: ' . $page->path, $page_tests{ $page->path }, $output;
        }
        else {
            fail "Unknown page: " . $page->path;
        }

    }

    ok !@warnings, "no warnings!" or diag join "\n", @warnings;
}

1;
__END__


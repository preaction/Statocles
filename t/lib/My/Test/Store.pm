package My::Test::Store;

use Getopt::Long;

use My::Test;
use Mojo::Loader qw( find_modules load_class );
use Statocles::Base 'Role';


my @modules;

BEGIN {
    @modules = find_modules( __PACKAGE__ );
}


has class => (
    is       => 'ro',
    isa      => Str,
    required => 1,
);

has share_dir => (
    is       => 'ro',
    isa      => AbsPath,
    coerce   => 1,
    required => 1,
);

sub run_tests { }

my %tests;

INIT {

    my $package = __PACKAGE__;

    my %opts;
    GetOptions( \ %opts, 'include|I=s@', 'exclude|I=s@' )
      or die( "can't parse options" );

    if ( $opts{include} ) {

        for my $include ( @{ $opts{include} } ) {

            if ( $include =~ m{^/.*/$} ) {

                ( $include ) = $include =~ m{/(.*)/};
                $include = qr/$include/;

                $tests{$_} = undef for grep {
                    ( my $test = $_ ) =~ s/^${package}:://;
                    $test =~ $include;
                } @modules;
            }
            else {
                $tests{$_} = undef for grep { $_ eq __PACKAGE__ . '::' . $include } @modules;
            }
        }

    }

    else {

        @tests{@modules} = undef;
    }

    if ( $opts{exclude} ) {

        for my $exclude ( @{ $opts{exclude} } ) {

            if ( $exclude =~ m{^/.*/$} ) {
                $exclude = qr/$exclude/;

                delete $tests{$_} for grep {
                    ( my $test = $_ ) =~ s/^${package}:://;
                    $test =~ $exclude
                } @modules;
            }
            else {
                delete $tests{$_} for grep { $_ eq __PACKAGE__ . '::' . $exclude } @modules;
            }

        }
    }


    with $_ for keys %tests;

    around run_tests => sub {

        my $orig = shift;
        my $self = shift;


        subtest $self->class => sub {

            $self->$orig( @_ );

        };

    };

}


sub build {

    my $self = shift;
    my $class = $self->class;

    $class->new( $self->args( @_ ) );
}

requires 'args';
requires 'required';
1;

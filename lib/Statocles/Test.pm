package Statocles::Test;
# ABSTRACT: Common test routines for Statocles

use Statocles::Base;
use Test::More;
use Test::Exception;
use Test::Deep;
use base qw( Exporter );
our @EXPORT_OK = qw( test_constructor );

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

1;
__END__



use Statocles::Base 'Test';
use Statocles::Image;

subtest 'constructor' => sub {
    my %required = (
        src => '/images/test.jpg',
    );

    test_constructor(
        'Statocles::Image',
        required => \%required,
        default => {
            role => 'presentation',
        },
    );

    subtest 'coerce' => sub {

        subtest 'Path object' => sub {
            my $img;
            lives_ok {
                $img = Statocles::Image->new(
                    src => Path::Tiny->new( 'images', 'test.jpg' ),
                );
            } or return;
            is $img->src, 'images/test.jpg';
        };
    };

    subtest 'default role' => sub {
        my $img = Statocles::Image->new(
            src => 'images/test.jpg',
            alt => 'Test alt',
        );
        is $img->role, undef, 'no default if alt set';
    };
};

done_testing;

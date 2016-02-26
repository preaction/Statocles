
use Test::Lib;
use My::Test;
use Statocles::App::Perldoc;

my $SHARE_DIR = path( __DIR__ )->parent->parent->child( 'share' );
my $site = build_test_site(
    theme => $SHARE_DIR->child( 'theme' ),
);

my %required = (
    url_root => '/pod',
    modules => [qw( My )],
    index_module => 'My',
);

test_constructor(
    "Statocles::App::Perldoc",
    required => \%required,
    default => {
        inc => [ map { Path::Tiny->new( $_ ) } @INC ],
        weave => 0,
        weave_config => Path::Tiny->new( './weaver.ini' ),
    },
);

subtest 'attribute types/coercions' => sub {
    subtest 'inc' => sub {

        subtest 'all strings' => sub {
            my $app;
            lives_ok {
                $app = Statocles::App::Perldoc->new(
                    %required,
                    inc => [ 'test', 'two' ],
                )
            };

            cmp_deeply $app->inc, array_each( isa( 'Path::Tiny' ) );
            is $app->inc->[0]->stringify, "test";
            is $app->inc->[1]->stringify, "two";
        };

        subtest 'some strings / some paths' => sub {
            my $app;
            lives_ok {
                $app = Statocles::App::Perldoc->new(
                    %required,
                    inc => [ 'test', Path::Tiny->new( 'two' ) ],
                )
            };

            cmp_deeply $app->inc, array_each( isa( 'Path::Tiny' ) );
            is $app->inc->[0]->stringify, "test";
            is $app->inc->[1]->stringify, "two";
        };
    };

    subtest 'weave_config' => sub {
        subtest 'string' => sub {
            my $app;
            lives_ok {
                $app = Statocles::App::Perldoc->new(
                    %required,
                    weave_config => 'foo',
                );
            };

            isa_ok $app->weave_config, 'Path::Tiny';
            is $app->weave_config->stringify, 'foo';
        };
    };

};

done_testing;

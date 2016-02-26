
use Test::Lib;
use My::Test;
use Statocles::Site;
use Statocles::Theme;
use Statocles::Store;
my $SHARE_DIR = path( __DIR__, '..', 'share' );

my $cwd = cwd;
my $tmp = tempdir;
chdir $tmp;

my %required = (
    deploy => '.',
);

# We need this to make the store to check the default
mkdir '.statocles';
mkdir '.statocles/build';

test_constructor(
    'Statocles::Site',
    required => \%required,
    default => {
        index => '/',
        theme => Statocles::Theme->new( store => '::default' ),
        build_store => Statocles::Store->new( path => '.statocles/build' ),
    },
);

chdir $cwd;

subtest 'build dir gets created automatically' => sub {
    my $tmp = tempdir;
    chdir $tmp;

    lives_ok { Statocles::Site->new( %required ) };
    ok -d '.statocles/build', 'directory was created';

    lives_ok { Statocles::Site->new( build_store => 'builddir', %required ) };
    ok -d 'builddir', 'directory was created';

    lives_ok { Statocles::Site->new( build_store => 'some/deep/build/dir', %required ) };
    ok -d 'some/deep/build/dir', 'directory was created';

    chdir $cwd;
};

done_testing;

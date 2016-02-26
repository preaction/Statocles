
use Test::Lib;
use My::Test;
my $SHARE_DIR = path( __DIR__, '..', 'share' );
use Statocles::Theme;

my $theme = Statocles::Theme->new(
    store => $SHARE_DIR->child( 'theme' ),
);

# This will be set by the helper when the helper is called and will
# contain all the args given to the helper
my @helper_args;

subtest 'add helpers' => sub {
    my $helper_sub = sub { @helper_args = @_; return "helper content" };
    lives_ok {
        $theme->helper( foo => $helper_sub );
    } 'helper method called successfully';
};

subtest 'call helper' => sub {
    subtest 'no args' => sub {
        my $tmpl = $theme->build_template( "test/path.html", '<%= foo %>' );
        is $tmpl->render( foo => "bar" ), "helper content\n", 'helper returns content';
        cmp_deeply \@helper_args, [ { foo => "bar" } ], 'args are correct';
    };
    subtest 'with args' => sub {
        my $tmpl = $theme->build_template( "test/path.html", '<%= foo "one", "two" %>' );
        is $tmpl->render( foo => "bar" ), "helper content\n", 'helper returns content';
        cmp_deeply \@helper_args, [ { foo => "bar" }, "one", "two" ], 'args are correct';
    };
};

done_testing;

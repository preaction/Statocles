
use Test::Lib;
use My::Test;
use Statocles::Template;
my $SHARE_DIR = path( __DIR__, '..', 'share' );
build_test_site( theme => $SHARE_DIR->child( 'theme' ) );

subtest 'merge state' => sub {
    my $tmpl = Statocles::Template->new(
        state => {
            foo => 'bar',
        },
    );

    $tmpl->merge_state( { foo => 'baz', fuzz => 'buzz' } );
    is $tmpl->state->{ foo }, 'baz', 'foo is overwritten by merge';
    is $tmpl->state->{ fuzz }, 'buzz', 'fuzz is added by merge';
};

done_testing;

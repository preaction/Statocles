
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

subtest 'merge clones' => sub {
    my $tmpl = Statocles::Template->new(
        content => '<% content foo => "HAHAHA"; %>',
    );

    my $state = { content => { foo => 'baz', fuzz => 'buzz' } };
    $tmpl->merge_state( $state );
    $tmpl->render;
    is $tmpl->state->{ content }{ foo }, 'HAHAHA', 'foo is overwritten by content helper';
    is $state->{content}{foo}, 'baz', 'original ref is not changed';

};

done_testing;

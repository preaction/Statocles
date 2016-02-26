
use Test::Lib;
use My::Test;
my $SHARE_DIR = path( __DIR__, '..', 'share' );

{
    package My::Plugin;

    use Statocles::Base 'Class';
    with 'Statocles::Plugin';

    has _register_called => (
        is => 'rw',
    );

    has _last_args => (
        is => 'rw',
    );

    sub register {
        my ( $self, $site ) = @_;
        $self->_register_called( 1 );
        my $helper_sub = sub { $self->_last_args( \@_ ); return "helper content" };
        $site->theme->helper( foo => $helper_sub );
    }
}

my $site;

subtest 'register plugin' => sub {
    $site = build_test_site( plugins => {
        foo => My::Plugin->new,
    } );
    ok $site->plugins->{ foo }->_register_called, 'plugin register method was called';
};

subtest 'call helper' => sub {
    subtest 'no args' => sub {
        my $tmpl = $site->theme->build_template( "test/path.html", '<%= foo %>' );
        is $tmpl->render( foo => "bar" ), "helper content\n", 'helper returns content';
        cmp_deeply
            $site->plugins->{ foo }->_last_args,
            [ { foo => "bar" } ],
            'args are correct';
    };
    subtest 'with args' => sub {
        my $tmpl = $site->theme->build_template( "test/path.html", '<%= foo "one", "two" %>' );
        is $tmpl->render( foo => "bar" ), "helper content\n", 'helper returns content';
        cmp_deeply
            $site->plugins->{ foo }->_last_args,
            [ { foo => "bar" }, "one", "two" ],
            'args are correct';
    };
};

done_testing;

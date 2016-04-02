
use Test::Lib;
use My::Test;
use Statocles::Template;
my $SHARE_DIR = path( __DIR__, '..', 'share' );
build_test_site( theme => $SHARE_DIR->child( 'theme' ) );

subtest 'default content' => sub {
    my @warnings;
    local $SIG{ __WARN__ } = sub { push @warnings, @_ };

    my $t = Statocles::Template->new(
        content => <<ENDHTML,
%= content;
ENDHTML
    );

    is $t->render( content => "bar" ), "bar\n", 'content from vars is rendered';

    ok !@warnings, 'no warnings' or diag join "\n", @warnings;
};

subtest 'content string' => sub {
    my @warnings;
    local $SIG{ __WARN__ } = sub { push @warnings, @_ };

    my $t = Statocles::Template->new(
        content => <<ENDHTML,
% content foo => "bar";
%= content "foo";
ENDHTML
    );

    is $t->render, "bar\n", 'content section is rendered';
    is $t->state->{content}{foo}, "bar", 'content state is saved';

    ok !@warnings, 'no warnings' or diag join "\n", @warnings;
};

subtest 'content begin/end' => sub {
    my @warnings;
    local $SIG{ __WARN__ } = sub { push @warnings, @_ };

    my $t = Statocles::Template->new(
        content => <<ENDHTML,
<% content foo => begin %>bar<% end %>
%= content "foo";
ENDHTML
    );

    is $t->render, "\nbar\n", 'content section is rendered';
    is $t->state->{content}{foo}, "bar", 'content state is saved';

    ok !@warnings, 'no warnings' or diag join "\n", @warnings;
};

subtest 'replace content section' => sub {
    my @warnings;
    local $SIG{ __WARN__ } = sub { push @warnings, @_ };

    my $t = Statocles::Template->new(
        state => {
            content => {
                foo => 'baz',
            },
        },
        content => <<ENDHTML,
<% content foo => begin %>bar<% end %>
%= content "foo";
ENDHTML
    );

    is $t->render, "\nbar\n", 'correct content section is rendered';
    is $t->state->{content}{foo}, "bar", 'content state is saved';

    ok !@warnings, 'no warnings' or diag join "\n", @warnings;
};

subtest 'extend content section' => sub {
    my @warnings;
    local $SIG{ __WARN__ } = sub { push @warnings, @_ };

    my $t = Statocles::Template->new(
        state => {
            content => {
                foo => 'baz',
            },
        },
        content => <<ENDHTML,
<% content foo => begin %>bar <%= content "foo" %><% end %>
%= content "foo";
ENDHTML
    );

    is $t->render, "\nbar baz\n", 'extended content section is rendered';
    is $t->state->{content}{foo}, "bar baz", 'content state is saved';

    ok !@warnings, 'no warnings' or diag join "\n", @warnings;
};

subtest 'empty section' => sub {
    my @warnings;
    local $SIG{ __WARN__ } = sub { push @warnings, @_ };

    my $t = Statocles::Template->new(
        content => <<ENDHTML,
%= content "foo";
ENDHTML
    );

    is $t->render, "\n", 'content section is rendered';
    ok !exists $t->state->{content}{foo}, 'content state is not saved';

    ok !@warnings, 'no warnings' or diag join "\n", @warnings;
};

done_testing;

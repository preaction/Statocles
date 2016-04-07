
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

    my $page = Statocles::Page::Plain->new(
        path => '/index.html',
        content => 'blank',
    );

    my $t = Statocles::Template->new(
        content => <<ENDHTML,
% content foo => "bar";
%= content "foo";
ENDHTML
    );

    is $t->render( page => $page ), "bar\n", 'content section is rendered';
    is $page->_content_sections->{foo}, "bar", 'content state is saved';

    ok !@warnings, 'no warnings' or diag join "\n", @warnings;
};

subtest 'content begin/end' => sub {
    my @warnings;
    local $SIG{ __WARN__ } = sub { push @warnings, @_ };

    my $page = Statocles::Page::Plain->new(
        path => '/index.html',
        content => 'blank',
    );

    my $t = Statocles::Template->new(
        content => <<ENDHTML,
<% content foo => begin %>bar<% end %>
%= content "foo";
ENDHTML
    );

    is $t->render( page => $page ), "\nbar\n", 'content section is rendered';
    is $page->_content_sections->{foo}, "bar", 'content state is saved';

    ok !@warnings, 'no warnings' or diag join "\n", @warnings;
};

subtest 'replace content section' => sub {
    my @warnings;
    local $SIG{ __WARN__ } = sub { push @warnings, @_ };

    my $page = Statocles::Page::Plain->new(
        path => '/index.html',
        content => 'blank',
        _content_section => 'fuzz',
    );

    my $t = Statocles::Template->new(
        content => <<ENDHTML,
<% content foo => begin %>bar<% end %>
%= content "foo";
ENDHTML
    );

    is $t->render( page => $page ), "\nbar\n", 'correct content section is rendered';
    is $page->_content_sections->{foo}, "bar", 'content state is saved';

    ok !@warnings, 'no warnings' or diag join "\n", @warnings;
};

subtest 'extend content section' => sub {
    my @warnings;
    local $SIG{ __WARN__ } = sub { push @warnings, @_ };

    my $page = Statocles::Page::Plain->new(
        path => '/index.html',
        content => 'blank',
        _content_sections => {
            foo => 'baz',
        },
    );

    my $t = Statocles::Template->new(
        content => <<ENDHTML,
<% content foo => begin %>bar <%= content "foo" %><% end %>
%= content "foo";
ENDHTML
    );

    is $t->render( page => $page ), "\nbar baz\n", 'extended content section is rendered';
    is $page->_content_sections->{foo}, "bar baz", 'content state is saved';

    ok !@warnings, 'no warnings' or diag join "\n", @warnings;
};

subtest 'empty section' => sub {
    my @warnings;
    local $SIG{ __WARN__ } = sub { push @warnings, @_ };

    my $page = Statocles::Page::Plain->new(
        path => '/index.html',
        content => 'blank',
    );

    my $t = Statocles::Template->new(
        content => <<ENDHTML,
%= content "foo";
ENDHTML
    );

    is $t->render( page => $page ), "\n", 'content section is rendered';
    ok !exists $page->_content_sections->{foo}, 'content state is not saved';

    ok !@warnings, 'no warnings' or diag join "\n", @warnings;
};

done_testing;

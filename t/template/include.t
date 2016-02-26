
use Test::Lib;
use My::Test;
use Statocles::Template;
my $SHARE_DIR = path( __DIR__, '..', 'share' );
build_test_site( theme => $SHARE_DIR->child( 'theme' ) );

my %args = (
    title => 'Title',
    content => 'Content',
    extra => 'Extra',
);

subtest 'include another template' => sub {
    my $tmpl = Statocles::Template->new(
        path => $SHARE_DIR->child( 'tmpl', 'include_with_template.html.ep' ),
        theme => $SHARE_DIR->child( 'tmpl' ),
    );
    is $tmpl->render( %args ), "INCLUDE Title\n ENDINCLUDE Title Content\n";
};

subtest 'include with arguments' => sub {
    my $tmpl = Statocles::Template->new(
        path => $SHARE_DIR->child( 'tmpl', 'include_with_template_args.html.ep' ),
        theme => $SHARE_DIR->child( 'tmpl' ),
    );
    eq_or_diff $tmpl->render( %args ), "INCLUDE New Title\n ENDINCLUDE Title Content\n";
};

subtest 'include a plain HTML file' => sub {
    my $tmpl = Statocles::Template->new(
        path => $SHARE_DIR->child( 'tmpl', 'include_with_html.html.ep' ),
        theme => $SHARE_DIR->child( 'tmpl' ),
    );
    is $tmpl->render( %args ), "INCLUDE INCLUDEDHTML\n ENDINCLUDE Title Content\n";
};

subtest 'empty include' => sub {
    my $tmpl = Statocles::Template->new(
        path => $SHARE_DIR->child( 'tmpl', 'include_with_empty.html.ep' ),
        theme => $SHARE_DIR->child( 'tmpl' ),
    );
    my @warn;
    local $SIG{__WARN__} = sub { push @warn, @_ };
    eq_or_diff $tmpl->render( %args ), "INCLUDE  ENDINCLUDE Title Content\n";
    ok !@warn, 'no warnings from empty include' or diag explain \@warn;
};

subtest 'missing include dies' => sub {
    my $tmpl = Statocles::Template->new(
        path => $SHARE_DIR->child( 'tmpl', 'include_with_template.html.ep' ),
        theme => $SHARE_DIR,
        include_stores => [
            $SHARE_DIR->child( 'store', 'docs' ),
        ],
    );
    throws_ok {
        $tmpl->render( %args );
    } qr{Error in template: Can not find include "included_template[.]html[.]ep" in include directories: "[^"]+/share/store/docs", "[^"]+/share"};
};

subtest 'add template include store' => sub {

    subtest 'template include overrides theme include' => sub {
        my $tmpl = Statocles::Template->new(
            path => $SHARE_DIR->child( 'tmpl', 'include_with_template.html.ep' ),
            theme => $SHARE_DIR->child( 'theme' ),
            include_stores => [
                $SHARE_DIR->child( 'tmpl' ),
            ],
        );
        is $tmpl->render( %args ), "INCLUDE Title\n ENDINCLUDE Title Content\n";
    };

    subtest 'falls back to theme include' => sub {
        my $tmpl = Statocles::Template->new(
            path => $SHARE_DIR->child( 'tmpl', 'include_theme_file.html.ep' ),
            theme => $SHARE_DIR->child( 'theme' ),
            include_stores => [
                $SHARE_DIR->child( 'tmpl' ),
            ],
        );
        is $tmpl->render( %args ), "INCLUDE # Title\n ENDINCLUDE Title Content\n";
    };
};

done_testing;

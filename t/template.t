
use Statocles::Base 'Test';
use Statocles::Template;
my $SHARE_DIR = path( __DIR__, 'share' );
build_test_site( theme => $SHARE_DIR->child( 'theme' ) );

my %args = (
    title => 'Title',
    content => 'Content',
    extra => 'Extra',
);

subtest 'template string' => sub {
    my $t = Statocles::Template->new(
        content => '<%= $title %> <%= $content %>',
    );
    is $t->render( %args ), "Title Content\n";
};

subtest 'template from file' => sub {
    my $t = Statocles::Template->new(
        path => $SHARE_DIR->child( 'tmpl', 'page.html.ep' ),
    );
    is $t->render( %args ), "Title Content\n";
};

subtest 'invalid template coercions' => sub {
    my $coerce = Statocles::Template->coercion;
    throws_ok {
        $coerce->( undef );
    } qr{Template is undef};
};

subtest 'template with errors' => sub {
    my $tmpl = Statocles::Template->new(
        path => $SHARE_DIR->child( 'tmpl', 'error.html.ep' ),
    );
    throws_ok {
        $tmpl->render( title => "whatevers" );
    } qr{Error in template};
};

subtest 'template include' => sub {
    subtest 'include another template' => sub {
        my $tmpl = Statocles::Template->new(
            path => $SHARE_DIR->child( 'tmpl', 'include_with_template.html.ep' ),
            store => $SHARE_DIR->child( 'tmpl' ),
        );
        is $tmpl->render( %args ), "INCLUDE Title\n ENDINCLUDE Title Content\n";
    };

    subtest 'include a plain HTML file' => sub {
        my $tmpl = Statocles::Template->new(
            path => $SHARE_DIR->child( 'tmpl', 'include_with_html.html.ep' ),
            store => $SHARE_DIR->child( 'tmpl' ),
        );
        is $tmpl->render( %args ), "INCLUDE INCLUDEDHTML\n ENDINCLUDE Title Content\n";
    };

    subtest 'missing include dies' => sub {
        my $tmpl = Statocles::Template->new(
            path => $SHARE_DIR->child( 'tmpl', 'include_with_template.html.ep' ),
            store => $SHARE_DIR,
        );
        throws_ok {
            $tmpl->render( %args );
        } qr{Error in template: Can not find include "included_template[.]html[.]ep" in store};
    };
};

done_testing;

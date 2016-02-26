
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

subtest 'template string' => sub {
    my $t = Statocles::Template->new(
        content => '<%= $title %> <%= content %>',
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

subtest 'template comments' => sub {
    my $tmpl = Statocles::Template->new(
        path => $SHARE_DIR->child( 'tmpl', 'comment.html.ep' ),
    );
    is $tmpl->render, "<%= stuff() %>\n%= other_stuff()\n";
};

done_testing;

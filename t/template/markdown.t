
use Test::Lib;
use My::Test;
use Statocles::Template;
my $SHARE_DIR = path( __DIR__, '..', 'share' );
my $site = build_test_site( theme => $SHARE_DIR->child( 'theme' ) );

my %args = (
    title => 'Title',
    content => 'Content',
    extra => "# Markdown\n\nHello\n",
);

my $tmpl = Statocles::Template->new(
    path => $SHARE_DIR->child( 'tmpl', 'markdown.html.ep' ),
    theme => $SHARE_DIR->child( 'tmpl' ),
);

subtest 'markdown helper' => sub {
    my $out;
    lives_ok { $out = $tmpl->render( %args, site => $site ) };
    eq_or_diff $out, "Title Content\n<h1>Markdown</h1>\n\n<p>Hello</p>\n\n";
};

throws_ok { $tmpl->render( %args ) }
    qr/Cannot use markdown helper: No site object given to template/,
    'dies if no site object';

done_testing;

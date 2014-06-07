
use Statocles::Test;
use Statocles::Template;
my $SHARE_DIR = path( __DIR__, 'share' );

my %args = (
    title => 'Title',
    author => 'Author',
    content => 'Content',
    extra => 'Extra',
);

subtest 'template string' => sub {
    my $t = Statocles::Template->new(
        content => '<%= $title %> <%= $author %> <%= $content %>',
    );
    is $t->render( %args ), "Title Author Content\n";
};

subtest 'template from file' => sub {
    my $t = Statocles::Template->new(
        path => $SHARE_DIR->child( 'tmpl', 'page.html.ep' ),
    );
    is $t->render( %args ), "Title Author Content\n";
};

done_testing;

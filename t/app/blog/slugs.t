use utf8;
use Test::Lib;
use My::Test;
use Statocles::App::Blog;
my $SHARE_DIR = path(__DIR__)->parent->parent->child('share');

my $site = build_test_site( theme => $SHARE_DIR->child('theme'), );

my $app = Statocles::App::Blog->new(
    store    => $SHARE_DIR->child( 'app', 'blog' ),
    url_root => '/blog',
    site     => $site,
);

subtest 'slugs' => sub {
    my $slug_tests = [
        {
            title       => q(El Niño),
            slug        => q(el-nino),
            description => q(non-ASCII character in title),
        },
        {
            title       => q(How do I X?),
            slug        => q(how-do-i-x),
            description => q(trailing special character in title)
        },
        {
            title       => q(¿cómo i x),
            slug        => q(como-i-x),
            description => q(leading special character in title)
        },
        {
            title       => q(it's),
            slug        => 'its',
            description => q(apostrophe in title),
        }
    ];

    foreach my $case ( @{$slug_tests} ) {
        is( $app->make_slug( $case->{title} ),
            $case->{slug}, $case->{description} );
    }
};

done_testing;

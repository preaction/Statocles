
use Test::Lib;
use My::Test;
use Statocles;
use TestApp;
use TestDeploy;
use Statocles::Site;
use Statocles::Command::build;
my $SHARE_DIR = path( __DIR__, '..', 'share' );

my $site = Statocles::Site->new(
    store => tempdir,
    apps => {
        base => TestApp->new(
            url_root => '/',
            pages => [
                {
                    class => 'Statocles::Page::Plain',
                    path => '/index.html',
                    content => 'Index',
                },
                {
                    class => 'Statocles::Page::File',
                    path => '/image.png',
                    file_path => $SHARE_DIR->child( qw( store docs image.png ) ),
                },
            ],
        ),
    },
    deploy => TestDeploy->new,
);

subtest 'build site' => sub {
    my $tempdir = tempdir;

    my $cmd = Statocles::Command::build->new( site => $site );
    $cmd->run( $tempdir, '--date', '2018-01-01' );

    ok $tempdir->child( 'image.png' )->exists, 'Statocles::Page::File exists';

    ok $tempdir->child( 'index.html' )->exists, 'Statocles::Page::Plain exists';
    is $tempdir->child( 'index.html' )->slurp_utf8, "Index\n\n",
        'Statocles::Page::Plain content is correct';

    is_deeply $site->app( 'base' )->last_pages_args, [ date => '2018-01-01' ],
        'app pages() method args correct';
};

subtest 'Build site with default path' => sub {
    my $tempdir = $site->store->path;
    my $cmd = Statocles::Command::build->new( site => $site );
    $cmd->run();

    ok $tempdir->child( '.statocles', 'build', 'image.png' )->exists, 'Statocles::Page::File exists';

    ok $tempdir->child( '.statocles', 'build', 'index.html' )->exists, 'Statocles::Page::Plain exists';
    is $tempdir->child( '.statocles', 'build', 'index.html' )->slurp_utf8, "Index\n\n",
        'Statocles::Page::Plain content is correct';
};

done_testing;

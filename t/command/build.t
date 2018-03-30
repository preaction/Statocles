
use Test::Lib;
use My::Test;
use Statocles;
use TestApp;
use TestDeploy;
use Statocles::Site;
use Statocles::Command::build;
my $SHARE_DIR = path( __DIR__, '..', 'share' );

my $site = Statocles::Site->new(
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
                    path => '/static.txt',
                    file_path => $SHARE_DIR->child( qw( app basic static.txt ) ),
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

    ok $tempdir->child( 'static.txt' )->exists, 'Statocles::Page::File exists';
    is $tempdir->child( 'static.txt' )->slurp_utf8,
        $SHARE_DIR->child( qw( app basic static.txt ) )->slurp_utf8,
        'Statocles::Page::File content is correct';

    ok $tempdir->child( 'index.html' )->exists, 'Statocles::Page::Plain exists';
    is $tempdir->child( 'index.html' )->slurp_utf8, "Index\n\n",
        'Statocles::Page::Plain content is correct';

    is_deeply $site->app( 'base' )->last_pages_args, [ date => '2018-01-01' ],
        'app pages() method args correct';
};

subtest 'Build site with default path' => sub {
    my $cwd = cwd;
    my $tempdir = tempdir;
    chdir $tempdir;

    my $cmd = Statocles::Command::build->new( site => $site );
    $cmd->run();

    ok $tempdir->child( '.statocles', 'build', 'static.txt' )->exists, 'Statocles::Page::File exists';
    is $tempdir->child( '.statocles', 'build', 'static.txt' )->slurp_utf8,
        $SHARE_DIR->child( qw( app basic static.txt ) )->slurp_utf8,
        'Statocles::Page::File content is correct';

    ok $tempdir->child( '.statocles', 'build', 'index.html' )->exists, 'Statocles::Page::Plain exists';
    is $tempdir->child( '.statocles', 'build', 'index.html' )->slurp_utf8, "Index\n\n",
        'Statocles::Page::Plain content is correct';

    chdir $cwd;
};

done_testing;

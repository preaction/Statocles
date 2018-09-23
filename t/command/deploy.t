
use Test::Lib;
use My::Test;
use TestApp;
use TestDeploy;
use TestStore;
use Statocles::Site;
use Statocles::Command::deploy;
my $SHARE_DIR = path( __DIR__, '..', 'share' );

my @site_args = (
    store => TestStore->new(
        path => $SHARE_DIR->child( qw( store docs ) ),
        objects => [
            Statocles::Document->new(
                path => '/index.html',
                content => '<a href="/image.png">Image</a>',
            ),
            Statocles::File->new(
                path => '/image.png',
            ),
        ],
    ),
    apps => {
        base => TestApp->new(
            url_root => '/',
            pages => [ ],
        ),
    },
);

subtest 'deploy site' => sub {
    my $site = Statocles::Site->new(
        @site_args,
        deploy => TestDeploy->new,
    );

    my $cmd = Statocles::Command::deploy->new( build_dir => tempdir(), site => $site );
    $cmd->run( '--date', '2018-01-01', '--message', 'New site', '--clean' );

    is_deeply { @{ $site->app( 'base' )->last_pages_args } },
        { date => '2018-01-01' },
        'app pages() method options correct';
    my ( $path, $options ) = @{ $site->deploy->last_deploy_args };
    is $path."", $cmd->build_dir, 'deploy deploy() method path is correct';
    is_deeply $options,
        { date => '2018-01-01', message => 'New site', clean => 1 },
        'deploy deploy() method options correct';
};

subtest 'deploy site with deploy base_url' => sub {
    my $site = Statocles::Site->new(
        base_url => '/site_base',
        @site_args,
        deploy => TestDeploy->new( base_url => '/deploy_base' ),
    );

    my $cmd = Statocles::Command::deploy->new( build_dir => tempdir(), site => $site );
    $cmd->run;

    is_deeply { @{ $site->app( 'base' )->last_pages_args } },
        { base_url => '/deploy_base' },
        'app pages() method options correct';
    my ( $path, $options ) = @{ $site->deploy->last_deploy_args };
    is $path."", $cmd->build_dir, 'deploy deploy() method path is correct';
    is_deeply $options, { },
        'deploy deploy() method options correct';

    my $page_content = $cmd->build_dir->child( 'index.html' )->slurp_utf8;
    like $page_content, qr{<a href="/deploy_base/image.png">Image</a>}, 'HTML link is rewritten';
};

done_testing;


use Statocles::Base 'Test';
use Statocles::App;
use Test::Lib;
use TestApp;

my $site = Statocles::Site->new( deploy => tempdir );

subtest 'url' => sub {

    my $app = TestApp->new(
        url_root => '/blog/',
        pages => [],
    );

    is $app->url( '/index.html' ), '/blog/';
    is $app->url( '/page/2/index.html' ), '/blog/page/2/';
    is $app->url( '/tag/test.html' ), '/blog/tag/test.html';
};

done_testing;

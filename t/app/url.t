
use Statocles::Base 'Test';
use Statocles::App;
my $site = Statocles::Site->new( deploy => tempdir );

{
    package TestApp;
    use Statocles::Base 'Class';
    with 'Statocles::App';
    sub pages { }
}

subtest 'url' => sub {

    my $app = TestApp->new(
        url_root => '/blog/',
    );

    is $app->url( '/index.html' ), '/blog/';
    is $app->url( '/page/2/index.html' ), '/blog/page/2/';
    is $app->url( '/tag/test.html' ), '/blog/tag/test.html';
};

done_testing;

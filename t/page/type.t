
use Test::Lib;
use My::Test;
use Statocles::Site;
my $site = Statocles::Site->new( deploy => tempdir );

{
    package TestPage;
    use Statocles::Base 'Class';
    with 'Statocles::Page';
}

sub test_type {
    my ( $type, @paths ) = @_;
    for my $path ( @paths ) {
        my $page = TestPage->new(
            path => $path,
        );
        is $page->type, $type, "$path is a $type";
    }
}

subtest 'type detection' => sub {

    subtest 'text' => sub {
        subtest 'html' => \&test_type, 'text/html',
            '/index.html';
        subtest 'markdown' => \&test_type, 'text/markdown',
            '/index.markdown';
        subtest 'css' => \&test_type, 'text/css',
            '/index.css';
    };

    subtest 'image' => sub {
        subtest 'jpeg' => \&test_type, 'image/jpeg',
            '/images/test.jpg',
            '/images/derp.jpeg';
        subtest 'png' => \&test_type, 'image/png',
            '/images/test.png';
        subtest 'gif' => \&test_type, 'image/gif',
            '/images/test.gif';
    };

    subtest 'application' => sub {
        subtest 'rss' => \&test_type, 'application/rss+xml',
            '/index.rss';
        subtest 'atom' => \&test_type, 'application/atom+xml',
            '/index.atom';
        subtest 'js' => \&test_type, 'application/javascript',
            '/js/app.js';
        subtest 'json' => \&test_type, 'application/json',
            '/data/users.json';
    };
};

done_testing;

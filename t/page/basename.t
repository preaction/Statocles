
use Test::Lib;
use My::Test;
use Statocles::Site;
use Statocles::Link;
my $site = Statocles::Site->new( deploy => tempdir );

{
    package TestPage;
    use Statocles::Base 'Class';
    with 'Statocles::Page';
}

subtest 'basename' => sub {
    my $p = TestPage->new(
        path => '/blog/index.html',
    );
    is $p->basename, 'index.html';
};

subtest 'dirname' => sub {
    subtest 'root' => sub {
        my $p = TestPage->new(
            path => '/index.html',
        );
        is $p->dirname, '/';
    };

    subtest 'non-root' => sub {
        my $p = TestPage->new(
            path => '/blog/index.html',
        );
        is $p->dirname, '/blog';
    };
};

done_testing;

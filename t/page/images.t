
use Test::Lib;
use My::Test;
use Statocles::Site;
use Statocles::Image;
my $site = Statocles::Site->new( deploy => tempdir );

{
    package TestPage;
    use Statocles::Base 'Class';
    with 'Statocles::Page';
}

subtest 'images' => sub {

    my $page = TestPage->new(
        path => '/index.rss',
        images => {
            title => Statocles::Image->new(
                src => '/title.jpg',
                alt => 'Title image',
            ),
            banner => Statocles::Image->new(
                src => 'banner.jpg',
            ),
        },
    );

    subtest 'scalar' => sub {
        cmp_deeply
            scalar $page->images( 'title' ),
            Statocles::Image->new(
                src => '/title.jpg',
                alt => 'Title image',
            );
    };

};

done_testing;

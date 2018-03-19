use Test::Lib;
use My::Test;
use Statocles::Document;

my %default = ();

subtest 'status' => sub {
    my $doc = Statocles::Document->new(
        %default,
    );

    is $doc->status => 'published';

};

subtest 'images' => sub {
    my $doc = Statocles::Document->new(
        %default,
        images => {
            title => {
                src => '/image.jpg',
                alt => 'Title image',
            },
            banner => 'banner.jpg',
        },
    );

    my $img = $doc->images( 'title' );
    isa_ok $img, 'Statocles::Image';
    is $img->src => '/image.jpg';
    is $img->alt => 'Title image';

    $img = $doc->images( 'banner' );
    isa_ok $img, 'Statocles::Image';
    is $img->src, 'banner.jpg';

};

subtest 'author' => sub {

    subtest 'coerce from string' => sub {
        my $doc = Statocles::Document->new(
            author => 'Doug Bell <doug@example.com>',
        );
        isa_ok $doc->author, 'Statocles::Person', 'author isa Person object';
        is $doc->author->name, 'Doug Bell', 'author name is correct';
        is $doc->author->email, 'doug@example.com', 'author email is correct';
        is $doc->author."", 'Doug Bell', 'author stringification is correct';
    };
};

done_testing;

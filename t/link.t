use Test::Lib;
use My::Test;
use Mojo::DOM;
use Statocles::Link;

subtest 'constructor' => sub {
    my %required = (
        href => '/blog',
    );

    test_constructor(
        'Statocles::Link',
        required => \%required,
    );

    subtest 'coerce' => sub {

        subtest 'Path object' => sub {
            my $link;
            lives_ok {
                $link = Statocles::Link->new(
                    href => Path::Tiny->new( 'test', 'index.html' ),
                    text => 'Text',
                );
            } or return;
            is $link->href, '/test/index.html';
        };
    };
};

subtest 'new_from_element' => sub {
    subtest 'basic items' => sub {
        my $dom = Mojo::DOM->new( '<a href="http://example.com">Link text</a>' );
        cmp_deeply(
            Statocles::Link->new_from_element( $dom->at( 'a' ) ),
            Statocles::Link->new(
                href => 'http://example.com',
                text => 'Link text',
            ),
        );
    };
};

done_testing;

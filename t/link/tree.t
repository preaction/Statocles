
use Test::Lib;
use My::Test;
use Mojo::DOM;
use Statocles::Link::Tree;

subtest 'constructor' => sub {
    my %required = (
        href => '/blog',
    );

    test_constructor(
        'Statocles::Link::Tree',
        required => \%required,
    );

    subtest 'coerce' => sub {

        subtest 'Path object' => sub {
            my $link;
            lives_ok {
                $link = Statocles::Link::Tree->new(
                    href => Path::Tiny->new( 'test', 'index.html' ),
                    text => 'Text',
                );
            } or return;
            is $link->href, '/test/index.html';
        };

        subtest 'children' => sub {
            my $link;
            lives_ok {
                $link = Statocles::Link::Tree->new(
                    href => '/index.html',
                    text => 'Text',
                    children => [
                        '/blog',
                        {
                            href => '/projects',
                            text => 'Projects',
                        },
                    ],
                );
            } or return;

            is $link->href, '/index.html', 'parent href is correct';
            is $link->text, 'Text', 'parent text is correct';

            cmp_deeply
                $link->children,
                [
                    Statocles::Link::Tree->new(
                        href => '/blog',
                    ),
                    Statocles::Link::Tree->new(
                        href => '/projects',
                        text => 'Projects',
                    ),
                ],
                'child links are coerced correctly';
        };
    };
};

subtest 'new_from_element' => sub {
    subtest 'basic items' => sub {
        my $dom = Mojo::DOM->new( '<a href="http://example.com">Link text</a>' );
        cmp_deeply(
            Statocles::Link::Tree->new_from_element( $dom->at( 'a' ) ),
            Statocles::Link::Tree->new(
                href => 'http://example.com',
                text => 'Link text',
            ),
        );
    };
};

done_testing;

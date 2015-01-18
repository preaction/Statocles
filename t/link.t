
use Statocles::Base 'Test';
use Mojo::DOM;
use Statocles::Link;

subtest 'constructor' => sub {
    my %required = (
        text => 'Link text',
        href => '/blog',
    );

    test_constructor(
        'Statocles::Link',
        required => \%required,
    );
};

subtest 'new_from_element' => sub {
    subtest 'required items' => sub {
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

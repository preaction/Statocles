
use Statocles::Base 'Test';
use Statocles::Types qw( LinkArray LinkHash );

subtest 'Link types' => sub {

    subtest 'LinkArray' => sub {
        subtest 'arrayref of hashrefs' => sub {
            my $link_array = LinkArray->coercion->( [
                {
                    text => 'link one',
                    href => 'http://example.com',
                },
                {
                    text => 'link two',
                    href => 'http://example.net',
                },
            ] );

            cmp_deeply $link_array, [
                Statocles::Link->new(
                    text => 'link one',
                    href => 'http://example.com',
                ),
                Statocles::Link->new(
                    text => 'link two',
                    href => 'http://example.net',
                ),
            ];

        };
    };

    subtest 'LinkHash' => sub {

        subtest 'coercions' => sub {
            subtest 'hashref of arrayrefs of hashrefs' => sub {
                my $link_hash = LinkHash->coercion->( {
                    main => [
                        {
                            text => 'link one',
                            href => 'http://example.com',
                        },
                        {
                            text => 'link two',
                            href => 'http://example.net',
                        },
                    ],
                } );

                cmp_deeply $link_hash, {
                    main => [
                        Statocles::Link->new(
                            text => 'link one',
                            href => 'http://example.com',
                        ),
                        Statocles::Link->new(
                            text => 'link two',
                            href => 'http://example.net',
                        ),
                    ],
                };

            };

            subtest 'hashref of hashrefs (single link)' => sub {
                my $link_hash = LinkHash->coercion->( {
                    alternate => {
                        text => 'link one',
                        href => 'http://example.com',
                    },
                } );

                cmp_deeply $link_hash, {
                    alternate => [
                        Statocles::Link->new(
                            text => 'link one',
                            href => 'http://example.com',
                        ),
                    ],
                };

            };
        };
    };
};

done_testing;

use Test::Lib;
use My::Test;
use Statocles::Types qw(
    Link LinkArray LinkHash DateTimeObj Person
    LinkTree LinkTreeArray
);

subtest 'Link types' => sub {

    subtest 'Link' => sub {

        subtest 'from String' => sub {
            my $link = Link->coerce( "http://example.com" );
            cmp_deeply $link, Statocles::Link->new( href => "http://example.com" );
        };

        subtest 'from Hashref' => sub {
            my $link = Link->coerce( { href => "http://example.com", rel => 'alternate' } );
            cmp_deeply $link, Statocles::Link->new( href => "http://example.com", rel => 'alternate' );
        };

    };

    subtest 'LinkArray' => sub {
        subtest 'arrayref of hashrefs' => sub {
            my $link_array = LinkArray->coercion->( [
                'http://example.com',
                {
                    text => 'link two',
                    href => 'http://example.net',
                },
            ] );

            cmp_deeply $link_array, [
                Statocles::Link->new(
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
                        'http://example.com',
                        {
                            text => 'link two',
                            href => 'http://example.net',
                        },
                    ],
                } );

                cmp_deeply $link_hash, {
                    main => [
                        Statocles::Link->new(
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

            subtest 'hashref of strings (single link)' => sub {
                my $link_hash = LinkHash->coercion->( {
                    alternate => 'http://example.com',
                } );

                cmp_deeply $link_hash, {
                    alternate => [
                        Statocles::Link->new(
                            href => 'http://example.com',
                        ),
                    ],
                };

            };
        };
    };

    subtest 'LinkTree' => sub {

        subtest 'from String' => sub {
            my $link = LinkTree->coerce( "http://example.com" );
            cmp_deeply $link, Statocles::Link::Tree->new( href => "http://example.com" );
        };

        subtest 'from Hashref' => sub {
            my $link = LinkTree->coerce( { href => "http://example.com", rel => 'alternate' } );
            cmp_deeply $link, Statocles::Link::Tree->new( href => "http://example.com", rel => 'alternate' );
        };

    };

    subtest 'LinkTreeArray' => sub {
        subtest 'arrayref of hashrefs' => sub {
            my $link_array = LinkTreeArray->coercion->( [
                'http://example.com',
                {
                    text => 'link two',
                    href => 'http://example.net',
                },
            ] );

            cmp_deeply $link_array, [
                Statocles::Link::Tree->new(
                    href => 'http://example.com',
                ),
                Statocles::Link::Tree->new(
                    text => 'link two',
                    href => 'http://example.net',
                ),
            ];

        };
    };

};

subtest 'DateTimeObj' => sub {
    subtest 'date string' => sub {
        my $got = DateTimeObj->coerce( '2015-01-01' );
        my $expect = DateTime::Moonpig->new( year => 2015, month => 1, day => 1 );
        cmp_deeply $got, $expect, 'parse DateTime::Moonpig from "YYYY-MM-DD"'
            or diag explain $got, $expect;
    };

    subtest 'datetime string' => sub {
        my $got = DateTimeObj->coerce( '2015-01-01 12:00:00' );
        my $expect = DateTime::Moonpig->new(
            year => 2015,
            month => 1,
            day => 1,
            hour => 12,
            minute => 0,
            second => 0,
        );
        cmp_deeply $got, $expect, 'parse DateTime::Moonpig from "YYYY-MM-DD HH:MM:SS"'
            or diag explain $got, $expect;
    };
};

subtest 'Person' => sub {

    subtest 'from String' => sub {
        subtest 'name only' => sub {
            my $person = Person->coerce( "Doug Bell" );
            cmp_deeply $person, Statocles::Person->new( name => "Doug Bell" );
        };
        subtest 'name + email' => sub {
            my $person = Person->coerce( 'Doug Bell <doug@example.com>' );
            cmp_deeply $person, Statocles::Person->new( name => "Doug Bell", email => 'doug@example.com' );
        };
    };

    subtest 'from Hashref' => sub {
        my $person = Person->coerce( { name => "Doug Bell", email => 'doug@example.com' } );
        cmp_deeply $person, Statocles::Person->new(
            name => "Doug Bell",
            email => 'doug@example.com',
        );
    };

};

done_testing;

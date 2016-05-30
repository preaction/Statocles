
use Test::Lib;
use My::Test;
use Mojo::DOM;
use Statocles::Person;

subtest 'constructor' => sub {
    my %required = (
        name => 'Doug Bell',
    );

    test_constructor(
        'Statocles::Person',
        required => \%required,
    );
};

subtest 'parse string' => sub {
    subtest 'Name <email@domain>' => sub {
        my $person = Statocles::Person->new( 'Doug Bell <doug@example.com>' );
        isa_ok $person, 'Statocles::Person';
        is $person->name, 'Doug Bell';
        is $person->email, 'doug@example.com';
    };

    subtest 'Name only' => sub {
        my $person = Statocles::Person->new( 'Doug Bell doug@example.com' );
        isa_ok $person, 'Statocles::Person';
        is $person->name, 'Doug Bell doug@example.com';
        ok !$person->email, 'no e-mail specified';
    };
};

done_testing;

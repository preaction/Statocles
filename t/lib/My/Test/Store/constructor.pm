package My::Test::Store::constructor;

use Test::Lib;
use My::Test;
use Module::Load;

use Moo::Role;

my $test_constructor = sub {

    my $self = shift;

    load $self->class;

    my $site = build_test_site( theme => $self->share_dir->child( 'theme' ) );

    test_constructor(
                     $self->class,
                     required => $self->required( path => $self->share_dir->child( qw( store docs ) ) ),
                    );

    subtest 'warn if path does not exist' => sub {
        my $path = $self->share_dir->child( qw( DOES_NOT_EXIST ) );
        lives_ok {
            $self->build( path => $path )->read_documents;
        }
        'store created with nonexistent path';

        cmp_deeply $site->log->history->[-1],
          [ ignore(), 'warn', qq{Store path "$path" does not exist} ]
          or diag explain $site->log->history->[-1];
    };


};

around run_tests => sub {

    my $orig = shift;

    my $self = shift;

    $self->$orig( @_ );

    subtest constructor => sub { $self->$test_constructor };
};



1;


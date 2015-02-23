
use Statocles::Base 'Test';
use Statocles::Store::File;
my $SHARE_DIR = path( __DIR__, '..', '..', 'share' );
build_test_site( theme => $SHARE_DIR->child( 'theme' ) );

test_constructor(
    'Statocles::Store::File',
    required => {
        path => $SHARE_DIR->child( qw( store docs ) ),
    },
);

subtest 'path must exist and be a directory' => sub {
    throws_ok {
        Statocles::Store::File->new(
            path => $SHARE_DIR->child( qw( DOES_NOT_EXIST ) ),
        );
    } qr{Store path '[^']+DOES_NOT_EXIST' does not exist};

    throws_ok {
        Statocles::Store::File->new(
            path => $SHARE_DIR->child( qw( store docs required.markdown ) ),
        );
    } qr{Store path '[^']+required\.markdown' is not a directory};

};

done_testing;

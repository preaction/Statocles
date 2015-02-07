
use Statocles::Base 'Test';
use Statocles::Deploy::File;

my $SHARE_DIR = path( __DIR__ )->parent->child( 'share' );

my @temp_args;
if ( $ENV{ NO_CLEANUP } ) {
    @temp_args = ( CLEANUP => 0 );
}

my $build_store = Statocles::Store::File->new(
    path => $SHARE_DIR->child( qw( deploy ) ),
);

subtest 'constructor' => sub {
    test_constructor(
        'Statocles::Deploy::File',
        default => {
            path => Path::Tiny->new( '.' ),
        },
    );
};

subtest 'deploy' => sub {
    my $tmpdir = tempdir( @temp_args );
    diag "TMP: " . $tmpdir if @temp_args;

    my $deploy = Statocles::Deploy::File->new(
        path => $tmpdir,
    );
    $deploy->deploy( $build_store );

    subtest 'files are correct' => sub {
        my $file_iter = $build_store->find_files;
        while ( my $file = $file_iter->() ) {
            ok $tmpdir->child( $file->path )->exists,
                'page ' . $file->path . ' is in deploy path';
        }
    };
};

done_testing;

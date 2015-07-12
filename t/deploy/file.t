
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

    my %paths = (
        'doc.markdown' => 1,
        'foo/index.html' => 1,
        'index.html' => 1,
    );

    subtest 'files are correct' => sub {
        my @found;
        my $iter = $tmpdir->iterator({ recurse => 1 });
        while ( my $file = $iter->() ) {
            next if $file->is_dir;
            my $rel_file = $file->relative( $tmpdir );
            ok $paths{ $rel_file }, 'page ' . $rel_file . ' is in deploy path';
            push @found, $rel_file;
        }
        is scalar @found, scalar keys %paths, 'all pages are found';
    };
};

subtest 'missing directory' => sub {
    my $store;
    lives_ok { $store = Statocles::Deploy::File->new( path => 'DOES_NOT_EXIST' ) };
    throws_ok { $store->deploy( $build_store ) }
        qr{\QDeploy directory "DOES_NOT_EXIST" does not exist (did you forget to make it?)};
};

done_testing;

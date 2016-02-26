use Test::Lib;
use My::Test;
use Statocles::Deploy::File;

my $SHARE_DIR = path( __DIR__ )->parent->child( 'share' );

my @temp_args;
if ( $ENV{ NO_CLEANUP } ) {
    @temp_args = ( CLEANUP => 0 );
}

my $build_store = Statocles::Store->new(
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
        site => build_test_site,
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

subtest '--clean' => sub {
    my $tmpdir = tempdir( @temp_args );
    diag "TMP: " . $tmpdir if @temp_args;

    # Add some files that should be cleaned up
    $tmpdir->child( 'needs-cleaning.txt' )->spew_utf8( 'Ha ha!' );

    my $deploy = Statocles::Deploy::File->new(
        path => $tmpdir,
        site => build_test_site,
    );

    subtest 'deploy without clean does not remove files' => sub {
        $deploy->deploy( $build_store );
        ok $tmpdir->child( 'needs-cleaning.txt' )->is_file, 'default deploy did not remove file';
    };

    subtest 'deploy with clean removes files first' => sub {
        $deploy->deploy( $build_store, clean => 1 );
        ok !$tmpdir->child( 'needs-cleaning.txt' )->is_file, 'default deploy remove files';
    };
};

subtest 'missing directory' => sub {
    my $store;
    lives_ok { $store = Statocles::Deploy::File->new( path => 'DOES_NOT_EXIST' ) };
    throws_ok { $store->deploy( $build_store ) }
        qr{\QDeploy directory "DOES_NOT_EXIST" does not exist (did you forget to make it?)};
};

done_testing;

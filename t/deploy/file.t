
use Test::Lib;
use My::Test;
use Statocles::Site;
use Statocles::Deploy::File;
use Statocles::Page::Plain;
use Statocles::Page::File;
use TestDeploy;

my $SHARE_DIR = path( __DIR__ )->parent->child( 'share' );

my @temp_args;
if ( $ENV{ NO_CLEANUP } ) {
    @temp_args = ( CLEANUP => 0 );
}

my $site = Statocles::Site->new(
    deploy => TestDeploy->new,
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

    # Add some files that should be cleaned up
    $tmpdir->child( 'needs-cleaning.txt' )->spew_utf8( 'Ha ha!' );

    my $deploy = Statocles::Deploy::File->new(
        path => $tmpdir,
        site => $site,
    );
    $deploy->deploy( $SHARE_DIR->child( 'deploy' ) );

    my %paths = (
        'doc.markdown' => 1,
        'index.html' => 1,
        'foo/index.html' => 1,
        'needs-cleaning.txt' => 1,
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

    subtest 'deploy with clean removes files first' => sub {
        delete $paths{ 'needs-cleaning.txt' };
        $deploy->deploy( $SHARE_DIR->child( 'deploy' ), clean => 1 );
        ok !$tmpdir->child( 'needs-cleaning.txt' )->is_file, 'default deploy remove files';
    };
};

subtest 'missing directory' => sub {
    my $store;
    lives_ok { $store = Statocles::Deploy::File->new( path => 'DOES_NOT_EXIST' ) };
    throws_ok { $store->deploy( $SHARE_DIR->child( 'deploy' ) ) }
        qr{\QDeploy directory "DOES_NOT_EXIST" does not exist (did you forget to make it?)};
};

done_testing;


use Statocles::Base 'Test';
use Statocles::Util qw( dircopy );
my $SHARE_DIR = path( __DIR__, 'share' );

subtest 'dircopy' => sub {
    my $tmp_dest = tempdir;
    dircopy $SHARE_DIR->child( qw( app plain ) ), $tmp_dest;
    ok $tmp_dest->child( 'index.markdown' )->is_file;
    ok $tmp_dest->child( 'foo' )->is_dir;
    ok $tmp_dest->child( qw( foo index.markdown ) )->is_file;
    ok $tmp_dest->child( qw( foo other.markdown ) )->is_file;
    ok $tmp_dest->child( qw( foo utf8.markdown ) )->is_file;

    subtest 'dir does not exist yet' => sub {
        my $tmp_dest = tempdir;

        dircopy $SHARE_DIR->child( qw( app plain ) ), $tmp_dest->child( 'missing' );
        ok $tmp_dest->child( qw( missing index.markdown ) )->is_file;
        ok $tmp_dest->child( qw( missing foo ) )->is_dir;
        ok $tmp_dest->child( qw( missing foo index.markdown ) )->is_file;
        ok $tmp_dest->child( qw( missing foo other.markdown ) )->is_file;
        ok $tmp_dest->child( qw( missing foo utf8.markdown ) )->is_file;

    };
};

done_testing;

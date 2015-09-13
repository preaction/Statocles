
use Statocles::Base 'Test';
use Statocles::Util qw( dircopy run_editor );
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

subtest 'run_editor' => sub {
    subtest 'no editor found' => sub {
        local $ENV{EDITOR};
        my $tmp = tempdir;
        ok !run_editor( $tmp->child( 'index.markdown' ) ), 'no editor, so return false';
    };

    subtest 'editor found' => sub {
        local $ENV{EDITOR} = "$^X " . $SHARE_DIR->child( 'bin', 'editor.pl' );
        local $ENV{STATOCLES_TEST_EDITOR_CONTENT} = "".$SHARE_DIR->child(qw( app blog draft a-draft-post.markdown ));
        my $tmp = tempdir;
        ok run_editor( $tmp->child( 'index.markdown' ) ), 'editor invoked, so return true';
    };

    subtest 'editor set but invalid' => sub {
        local $ENV{EDITOR} = "HOPEFULLY_DOES_NOT_EXIST";
        my $tmp = tempdir;
        throws_ok {
            run_editor( $tmp->child( 'index.markdown' ) );
        } qr{Failed to invoke editor "HOPEFULLY_DOES_NOT_EXIST": .*\n};
    };

    subtest 'editor dies by signal' => sub {
        local $ENV{EDITOR} = "$^X " . $SHARE_DIR->child( 'bin', 'editor.pl' ) . " --signal TERM";
        my $tmp = tempdir;
        throws_ok {
            run_editor( $tmp->child( 'index.markdown' ) );
        } qr[Editor "$ENV{EDITOR}" died from signal \d+\n];
    };

    subtest 'editor nonzero exit' => sub {
        local $ENV{EDITOR} = "$^X " . $SHARE_DIR->child( 'bin', 'editor.pl' ) . " --exit 1";
        my $tmp = tempdir;
        throws_ok {
            run_editor( $tmp->child( 'index.markdown' ) );
        } qr[Editor "$ENV{EDITOR}" exited with error \(non-zero\) status: 1\n];
    };
};

done_testing;

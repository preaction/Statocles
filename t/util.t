use Test::Lib;
use My::Test;
use Statocles::Util qw( trim dircopy run_editor uniq_by derp );
use Statocles::Link;
my $SHARE_DIR = path( __DIR__, 'share' );

use constant Win32 => $^O =~ /Win32/;

subtest 'trim' => sub {
    my $foo;
    my @warnings;
    local $SIG{__WARN__} = sub { push @warnings, @_ };

    $foo = ' foo',
    is trim $foo, 'foo', 'leading whitespace is trimmed';

    $foo = "foo\t\n";
    is trim $foo, 'foo', 'trailing whitespace is trimmed';

    $foo = ' foo ';
    is trim $foo, 'foo', 'leading and trailing whitespace is trimmed';

    $foo = '';
    is trim $foo, '', 'empty string is passed through';

    $foo = undef;
    is trim $foo, undef, 'undef is passed through';

    local $_ = " foo ";
    trim;
    is $_, "foo", '$_ is trimmed';

    is scalar @warnings, 0, 'no warnings about anything'
        or diag "Got warnings: " . join "\n", @warnings;
};

subtest 'dircopy' => sub {
    my $tmp_dest = tempdir;
    dircopy $SHARE_DIR->child( qw( app basic ) ), $tmp_dest;
    ok $tmp_dest->child( 'index.markdown' )->is_file;
    ok $tmp_dest->child( 'foo' )->is_dir;
    ok $tmp_dest->child( qw( foo index.markdown ) )->is_file;
    ok $tmp_dest->child( qw( foo other.markdown ) )->is_file;

    subtest 'dir does not exist yet' => sub {
        my $tmp_dest = tempdir;

        dircopy $SHARE_DIR->child( qw( app basic ) ), $tmp_dest->child( 'missing' );
        ok $tmp_dest->child( qw( missing index.markdown ) )->is_file;
        ok $tmp_dest->child( qw( missing foo ) )->is_dir;
        ok $tmp_dest->child( qw( missing foo index.markdown ) )->is_file;
        ok $tmp_dest->child( qw( missing foo other.markdown ) )->is_file;

    };
};

subtest 'run_editor' => sub {
    my $editor = join ' ', map qq{"$_"}, $^X, $SHARE_DIR->child( 'bin', 'editor.pl' );
    subtest 'no editor found' => sub {
        local $ENV{EDITOR};
        my $tmp = tempdir;
        ok !run_editor( $tmp->child( 'index.markdown' ) ), 'no editor, so return false';
    };

    subtest 'editor found' => sub {
        local $ENV{EDITOR} = $editor;
        local $ENV{STATOCLES_TEST_EDITOR_CONTENT} = "".$SHARE_DIR->child(qw( app blog draft a-draft-post.markdown ));
        my $tmp = tempdir;
        ok run_editor( $tmp->child( 'index.markdown' ) ), 'editor invoked, so return true';
    };

    subtest 'editor set but invalid' => sub {
        local $ENV{EDITOR} = "HOPEFULLY_DOES_NOT_EXIST";
        my $tmp = tempdir;
        throws_ok {
            run_editor( $tmp->child( 'index.markdown' ) );
        } qr{Editor "HOPEFULLY_DOES_NOT_EXIST" exited with error \(non-zero\) status: \d+\n};
    };

    if (!Win32) {
        subtest 'editor dies by signal' => sub {
            local $ENV{EDITOR} = $editor . " --signal TERM";
            my $tmp = tempdir;
            throws_ok {
                run_editor( $tmp->child( 'index.markdown' ) );
            } qr[Editor "\Q$ENV{EDITOR}\E" exited with error \(non-zero\) status: \d+\n];
        };
    }

    subtest 'editor nonzero exit' => sub {
        local $ENV{EDITOR} = $editor . " --exit 1";
        my $tmp = tempdir;
        throws_ok {
            run_editor( $tmp->child( 'index.markdown' ) );
        } qr[Editor "\Q$ENV{EDITOR}\E" exited with error \(non-zero\) status: \d+\n];
    };
};

subtest 'uniq_by' => sub {
    my @links = map { Statocles::Link->new( href => $_ ) } qw(
        /foo.html
        /bar.html
        /baz.html
        /foo.html
    );

    cmp_deeply [ uniq_by { $_->href } @links ], [ @links[0,1,2] ];
};

subtest 'derp' => sub {
    my @warnings;
    local $SIG{__WARN__} = sub { push @warnings, @_ };

    subtest 'one argument' => sub {
        subtest 'first call warns' => sub {
            derp 'Foo';
            is scalar @warnings, 1, '1 warning issued';
            is $warnings[-1], "Foo. See Statocles::Help::Upgrading\n",
                'derp message directs to upgrading guide';
            @warnings = ();
        };

        subtest 'second call with same args does not warn' => sub {
            derp 'Foo';
            is scalar @warnings, 0, "doesn't warn for same text a second time";
            @warnings = ();
        };
    };

    subtest 'many arguments' => sub {
        subtest 'first call warns' => sub {
            derp 'Foo %s', 'Bar';
            is scalar @warnings, 1, '1 warning issued';
            is $warnings[-1], "Foo Bar. See Statocles::Help::Upgrading\n",
                'derp message directs to upgrading guide';
            @warnings = ();
        };

        subtest 'second call with same args does not warn' => sub {
            derp 'Foo %s', 'Bar';
            is scalar @warnings, 0, "doesn't warn for same args a second time";
            @warnings = ();
        };

        subtest 'second call with different args warns' => sub {
            derp 'Foo %s', 'Baz';
            is scalar @warnings, 1, '1 warning issued';
            is $warnings[-1], "Foo Baz. See Statocles::Help::Upgrading\n",
                'derp message directs to upgrading guide';
            @warnings = ();
        };
    };

};

done_testing;

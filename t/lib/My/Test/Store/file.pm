package My::Test::Store::file;


use Test::Lib;
use My::Test;
use Capture::Tiny qw( capture );
use Module::Load;

use Moo::Role;

my $test_file = sub {

    my $self = shift;
    load $self->class;

    build_test_site( theme => $self->share_dir->child( 'theme' ) );

    my $ignored_store = $self->build(
        path => $self->share_dir->child( qw( store files ignore ) ), );

    subtest 'read files' => sub {
        my $store = $self->build(
            path => $self->share_dir->child( qw( store files ) ), );
        eq_or_diff $store->read_file( path( 'text.txt' ) ),
          $self->share_dir->child( qw( store files text.txt ) )->slurp_utf8;
    };

    subtest 'has file' => sub {
        my $store = $self->build(
            path => $self->share_dir->child( qw( store files ) ), );
        ok $store->has_file( path( 'text.txt' ) );
        ok !$store->has_file( path( 'missing.exe' ) );
    };

    subtest 'find files' => sub {
        my $store = $self->build(
            path => $self->share_dir->child( qw( store files ) ), );
        my @expect_paths = (
            path( qw( text.txt ) )->absolute( '/' ),
            path( qw( image.png ) )->absolute( '/' ),
        );
        my @expect_docs
          = ( path( qw( folder doc.markdown ) )->absolute( '/' ), );

        my $iter = $store->find_files;
        my @got_paths;
        while ( my $path = $iter->() ) {
            push @got_paths, $path;
        }

        cmp_deeply \@got_paths, bag( @expect_paths )
          or diag explain \@got_paths;

        subtest 'include documents' => sub {
            my $iter = $store->find_files( include_documents => 1 );
            my @got_paths;
            while ( my $path = $iter->() ) {
                push @got_paths, $path;
            }

            cmp_deeply \@got_paths, bag( @expect_paths, @expect_docs )
              or diag explain \@got_paths;
        };

        subtest 'can pass paths to read_file' => sub {
            my ( $path ) = grep { $_->basename eq 'text.txt' } @got_paths;
            eq_or_diff $store->read_file( $path ),
              $self->share_dir->child( qw( store files text.txt ) )->slurp_utf8;
        };

    };

    subtest 'write files' => sub {

        subtest 'string' => sub {
            my @warnings;
            local $SIG{__WARN__} = sub { push @warnings, $_[0] };

            my $tmpdir = tempdir;
            my $store = $self->build( path => $tmpdir, );

            my $content = "\x{2603} This is some plain text";

            my $path = path( qw( store files text.txt ) );
            # write_file with string is written using UTF-8
            $store->write_file( $path, $content );

            eq_or_diff $store->read_file( $path ), $content;

            ok !@warnings, 'no warnings from write'
              or diag "Got warnings: \n\t" . join "\n\t", @warnings;
        };

        subtest 'filehandle' => sub {
            my $tmpdir = tempdir;
            my $store = $self->build( path => $tmpdir, );

            subtest 'plain text files' => sub {
                my @warnings;
                local $SIG{__WARN__} = sub { push @warnings, $_[0] };

                my $path = path( qw( store files text.txt ) );
                my $fh
                  = $self->share_dir->child( $path  )->openr_raw;

                $store->write_file( $path , $fh );

                eq_or_diff $store->read_file_raw( $path ),
                  $self->share_dir->child( $path )->slurp_raw;

                ok !@warnings, 'no warnings from write'
                  or diag "Got warnings: \n\t" . join "\n\t", @warnings;
            };

            subtest 'images' => sub {
                my @warnings;
                local $SIG{__WARN__} = sub { push @warnings, $_[0] };

                my $path = path( qw( store files image.png ) );
                my $fh
                  = $self->share_dir->child( $path  )->openr_raw;

                $store->write_file( path( $path ), $fh );

                ok $store->read_file_raw( $path ) eq
                  $self->share_dir->child( $path )->slurp_raw,
                  'image content is correct';

                ok !@warnings, 'no warnings from write'
                  or diag "Got warnings: \n\t" . join "\n\t", @warnings;
            };

        };

        subtest 'Path::Tiny object' => sub {
            my $tmpdir = tempdir;
            my $store = $self->build( path => $tmpdir, );

            subtest 'plain text files' => sub {
                my @warnings;
                local $SIG{__WARN__} = sub { push @warnings, $_[0] };

                my $path = path( qw( store files text.txt ) );

                my $source_path = $self->share_dir->child( $path  );

                $store->write_file( $path, $source_path );

                eq_or_diff $store->read_file_raw($path), $source_path->slurp_raw;

                ok !@warnings, 'no warnings from write'
                  or diag "Got warnings: \n\t" . join "\n\t", @warnings;
            };

            subtest 'images' => sub {
                my @warnings;
                local $SIG{__WARN__} = sub { push @warnings, $_[0] };

                my $path = path( qw( store files image.png ) );
                my $source_path = $self->share_dir->child( $path  );

                $store->write_file( $path, $source_path );

                ok $store->read_file_raw( $path) eq $source_path->slurp_raw,
                  'image content is correct';

                ok !@warnings, 'no warnings from write'
                  or diag "Got warnings: \n\t" . join "\n\t", @warnings;
            };

        };
    };

    subtest 'remove' => sub {

        subtest 'file' => sub {
            my $tmpdir = tempdir;

            my $store = $self->build( path => $tmpdir );

            my $dir = path( 'foo', 'bar' );
            my $content = 'Hello';

            # write two files, delete one, check that
            # second file is stll there (thus so is the directory)
            # cannot check if an empty directory is there, as stores
            # may not have directories.

            my $f1 = path( $dir, 'baz0.txt' );
            my $f2 = path( $dir, 'baz1.txt' );

            for my $file ( $f1, $f2 ) {

                $store->write_file( $file, $content );

                ok $store->has_file( $file ), "file $file was created";

                eq_or_diff $store->read_file( $file ), $content,
                  "stored content for $file matches";
            }

            $store->remove( $f1 );

            ok ! $store->has_file( $f1 ), "store can't find deleted $f1";

            throws_ok { $store->read_file( $f1 ) }  qr/file/,
              "store can't return contents for deleted $f1";


            ok $store->has_file( $f2 ), "store can still find $f2";

            eq_or_diff $store->read_file( $f2 ), $content,
              "store can return contents for $f2";

        };

        subtest 'directory' => sub {
            my $tmpdir = tempdir;

            my $store = $self->build( path => $tmpdir );

            my $content = 'Hello';

            my $f1 = path( qw[ foo bar baz zero.txt ] );
            my $f2 = path( qw[ foo bar baz one.txt ] );
            my $f3 = path( qw[ foo bar zero.txt ] );
            my $f4 = path( qw[ foo zero.txt ] );

            for my $file ( $f1, $f2, $f3, $f4 ) {

                $store->write_file( $file, $content );

                ok $store->has_file( $file ), "file $file was created";

                eq_or_diff $store->read_file( $file ), $content,
                  "stored content for $file matches";
            }

            $store->remove( path( qw( foo bar baz ) ) );

            ok ! $store->has_file( $f1 ), "store can't find deleted $f1";
            throws_ok { $store->read_file( $f1 ) }  qr/file/,
              "store can't return contents for deleted $f1";

            ok ! $store->has_file( $f2 ), "store can't find deleted $f2";
            throws_ok { $store->read_file( $f2 ) }  qr/file/,
              "store can't return contents for deleted $f2";

            ok $store->has_file( $f3 ), "store can still find $f3 in parent dir";
            eq_or_diff $store->read_file( $f3 ), $content,
              "store can return contents for $f3";

            ok $store->has_file( $f3 ), "store can still find $f4 in grand parent dir";
            eq_or_diff $store->read_file( $f4 ), $content,
              "store can return contents for $f4";
        };
    };

    subtest 'verbose' => sub {

        local $ENV{MOJO_LOG_LEVEL} = 'debug';

        subtest 'write' => sub {
            my $tmpdir = tempdir;
            my $store = $self->build( path => $tmpdir, );

            my ( $out, $err, $exit ) = capture {
                $store->write_file( 'path.html' => 'HTML' );
            };
            like $err, qr{\QWrite file: path.html};
        };

        subtest 'read' => sub {
            my $store
              = $self->build( path => $self->share_dir->child( 'theme' ), );
            my $path = path( qw( blog post.html.ep ) );
            my ( $out, $err, $exit ) = capture {
                $store->read_file( $path );
            };
            like $err, qr{\QRead file: $path};

        };
    };

};

around run_tests => sub {

    my $orig = shift;
    my $self = shift;

    $self->$orig( @_ );
    subtest file => sub { $self->$test_file };
};

1;

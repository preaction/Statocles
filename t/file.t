
use Statocles::Test;
my $SHARE_DIR = catdir( __DIR__, 'share' );

use Statocles::File;
use Statocles::Document;

subtest 'new file' => sub {
    subtest 'path is required' => sub {
        dies_ok {
            Statocles::File->new;
        };
    };

    my $tmp = File::Temp->newdir;
    my $file = Statocles::File->new(
        path => catfile( $tmp->dirname, 'file.yml' ),
    );
    my @docs = (
        Statocles::Document->new(
            title => 'Document 1',
            author => 'preaction',
            content => 'body content',
        ),
        Statocles::Document->new(
            title => 'Document 2',
            author => 'postaction',
            content => 'more body content',
        ),
    );
    $file->add_document( @docs );

    subtest 'file get attached to documents' => sub {
        is $_->file, $file for @docs;
    };

    ok !-f $file->path, 'path does exist until write()';
    $file->write;
    ok -f $file->path, 'path now exists';

    my @yaml_docs = YAML::LoadFile( $file->path );
    cmp_deeply \@yaml_docs, [
        {
            title => 'Document 1',
            author => 'preaction',
            content => 'body content',
        },
        {
            title => 'Document 2',
            author => 'postaction',
            content => 'more body content',
        },
    ];
};

subtest 'read file' => sub {
    subtest 'path not found' => sub {
        my $file;
        lives_ok { 
            $file = Statocles::File->new(
                path => catfile( $SHARE_DIR, 'not_found.yml' ),
            );
        };
        dies_ok { $file->read };
    };

    my $file = Statocles::File->new(
        path => catfile( $SHARE_DIR, 'multi.yml' ),
    );
    lives_ok { $file->read };
    cmp_deeply $file->documents, [
        Statocles::Document->new(
            file => $file,
            title => 'Document 1',
            author => 'preaction',
            content => 'body content',
        ),
        Statocles::Document->new(
            file => $file,
            title => 'Document 2',
            author => 'postaction',
            content => 'more body content',
        ),
    ];
};

done_testing;

package Statocles::App::Blog;
# ABSTRACT: A blog application

use Statocles::Class;
use Statocles::Page;
use Statocles::File;
use File::Find qw( find );

extends 'Statocles::App';

has source_dir => (
    is => 'ro',
    isa => Str,
);

has url_root => (
    is => 'ro',
    isa => Str,
    required => 1,
);

has theme => (
    is => 'ro',
    isa => InstanceOf['Statocles::Theme'],
    required => 1,
);

has files => (
    is => 'rw',
    isa => ArrayRef[InstanceOf['Statocles::File']],
    lazy => 1,
    builder => 'read_files',
);

has documents => (
    is => 'rw',
    isa => ArrayRef[InstanceOf['Statocles::Document']],
    lazy => 1,
    builder => 'read',
);

sub read_files {
    my ( $self ) = @_;
    my @files;
    find(
        sub {
            if ( /[.]ya?ml$/ ) {
                push @files, Statocles::File->new(
                    path => $File::Find::name,
                );
            }
        },
        $self->source_dir,
    );
    return \@files;
}

sub read {
    my ( $self ) = @_;
    my @docs;
    for my $file ( @{ $self->files } ) {
        $file->read;
        push @docs, @{ $file->documents };
    }
    return \@docs;
}

sub path_to_url {
    my ( $self, $path ) = @_;
    my ( $volume, $dirs, $file ) = splitpath( $path );
    my ( $source_volume, $source_dir, undef ) = splitpath( $self->source_dir, 'no_file' );
    $dirs =~ s/$source_dir//;
    # $dirs may have empty parts (especially at the ends), so
    # remove them to make a nicer URL
    my @dir_parts = grep { $_ ne '' } splitdir( $dirs );
    $file =~ s/[.][^.]+$/.html/;
    return join( "/", $self->url_root, @dir_parts, $file ),
}

sub blog_pages {
    my ( $self ) = @_;
    my $source_dir = $self->source_dir;
    my @pages;
    for my $doc ( @{ $self->documents } ) {
        push @pages, Statocles::Page->new(
            layout => $self->theme->templates->{site}{layout},
            template => $self->theme->templates->{blog}{post},
            document => $doc,
            path => $self->path_to_url( $doc->file->path ),
        );
    }
    return @pages;
}

sub write {
    my ( $self, $root_dir ) = @_;
    for my $page ( $self->blog_pages ) {
        $page->write( $root_dir );
    }
}

1;

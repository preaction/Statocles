package Statocles::App::Blog;
# ABSTRACT: A blog application

use Statocles::Class;
use Statocles::Page;

extends 'Statocles::App';

has source => (
    is => 'ro',
    isa => InstanceOf['Statocles::Store'],
);

has destination => (
    is => 'rw',
    isa => InstanceOf['Statocles::Store'],
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

sub blog_pages {
    my ( $self ) = @_;
    my @pages;
    for my $doc ( @{ $self->source->documents } ) {
        my $path = join "/", $self->url_root, $doc->path;
        $path =~ s{/{2,}}{/}g;
        $path =~ s{[.]\w+$}{.html};
        push @pages, Statocles::Page->new(
            layout => $self->theme->templates->{site}{layout},
            template => $self->theme->templates->{blog}{post},
            document => $doc,
            path => $path,
        );
    }
    return @pages;
}

sub pages {
    my ( $self ) = @_;
    return ( $self->blog_pages );
}

sub write {
    my ( $self ) = @_;
    for my $page ( $self->pages ) {
        $self->destination->write_page( $page );
    }
}

1;

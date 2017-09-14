package Statocles::App::Role::Store;
our $VERSION = '0.087';
# ABSTRACT: Role for applications using files

=head1 SYNOPSIS

    package MyApp;
    use Statocles::Base 'Class';
    with 'Statocles::App::Role::Store';

    around pages => sub {
        my ( $orig, $self, %options ) = @_;
        my @pages = $self->$orig( %options );

        # ... Add/remove pages

        return @pages;
    };

=head1 DESCRIPTION

This role provides some basic functionality for those applications that want
to use L<store objects|Statocles::Store> to manage content with Markdown files.

=cut

use Statocles::Base 'Role';
use Statocles::Page::Document;
use Statocles::Page::File;
with 'Statocles::App';

=attr store

The directory path or L<store object|Statocles::Store> containing this app's
documents. Required.

=cut

has store => (
    is => 'ro',
    isa => Store,
    required => 1,
    coerce => Store->coercion,
);

=method pages

    my @pages = $app->pages;

Get all the pages for this application. Markdown documents are wrapped
in L<Statocles::Page::Document> objects, and everything else is wrapped in
L<Statocles::Page::File> objects.

=cut

sub pages {
    my ( $self, %options ) = @_;
    my @pages;

    my @paths;
    my $iter = $self->store->find_files( include_documents => 1 );
    while ( my $path = $iter->() ) {
        push @paths, $path;
    }

    PATH:
    for my $path ( @paths ) {

        # Check for hidden files and folders
        next if $path->basename =~ /^[.]/;
        my $parent = $path->parent;
        while ( !$parent->is_rootdir ) {
            next PATH if $parent->basename =~ /^[.]/;
            $parent = $parent->parent;
        }

        if ( $self->store->is_document( $path ) ) {
            my $page_path = $path;
            $page_path =~ s{[.]\w+$}{.html};

            my %args = (
                path => $page_path,
                app => $self,
                layout => $self->template( 'layout.html' ),
                document => $self->store->read_document( $path ),
            );

            push @pages, Statocles::Page::Document->new( %args );
        }
        else {
            # If there's a markdown file, don't keep the html file, since
            # we'll be building it from the markdown
            if ( $path =~ /[.]html$/ ) {
                my $doc_path = "$path";
                $doc_path =~ s/[.]html$/.markdown/;
                next if grep { $_ eq $doc_path } @paths;
            }

            push @pages, Statocles::Page::File->new(
                path => $path,
                file_path => $self->store->path->child( $path ),
            );
        }
    }

    return @pages;
}

1;

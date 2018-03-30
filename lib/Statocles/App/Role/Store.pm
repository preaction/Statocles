package Statocles::App::Role::Store;
our $VERSION = '0.094';
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
    isa => StoreType,
    required => 1,
    coerce => StoreType->coercion,
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
    my $iter = $self->store->iterator;
    while ( my $obj = $iter->() ) {

        if ( $obj->isa( 'Statocles::Document' ) ) {
            my $page_path = $obj->path.'';
            $page_path =~ s{[.]\w+$}{.html};

            my %args = (
                path => $page_path,
                app => $self,
                layout => $self->template( 'layout.html' ),
                document => $obj,
            );

            push @pages, Statocles::Page::Document->new( %args );
        }
        else {
            # If there's a markdown file, don't keep the html file, since
            # we'll be building it from the markdown
            if ( $obj->path =~ /[.]html$/ ) {
                my $doc_path = $obj->path."";
                $doc_path =~ s/[.]html$/.markdown/;
                next if $self->store->has_file( $doc_path );
            }

            push @pages, Statocles::Page::File->new(
                app => $self,
                path => $obj->path->stringify,
                file_path => $self->store->path->child( $obj->path ),
            );
        }
    }

    return @pages;
}

1;

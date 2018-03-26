package Statocles::App::Static;
our $VERSION = '0.091';
# ABSTRACT: (DEPRECATED) Manage static files like CSS, JS, images, and other untemplated content

use Statocles::Base 'Class';
use Statocles::Page::File;
use Statocles::Util qw( derp );
with 'Statocles::App';

=attr store

The L<store|Statocles::Store> containing this app's files. Required.

=cut

has store => (
    is => 'ro',
    isa => Store,
    required => 1,
    coerce => Store->coercion,
);

=method pages

    my @pages = $app->pages;

Get the L<page objects|Statocles::Page> for this app.

=cut

sub pages {
    my ( $self ) = @_;

    derp qq{Statocles::App::Static has been replaced by Statocles::App::Basic and will be removed in 2.0. Change the app class to "Statocles::App::Basic" to silence this message.};

    my @pages;
    my $iter = $self->store->iterator;
    FILE: while ( my $obj = $iter->() ) {
        push @pages, Statocles::Page::File->new(
            path => $obj->path.'',
            file_path => $self->store->path->child( $obj->path ),
        );
    }

    return @pages;
}

1;
__END__

=head1 DESCRIPTION

B<NOTE:> This application's functionality has been added to
L<Statocles::App::Basic>. You can use the Basic app to replace this app. This
class will be removed with v2.0. See L<Statocles::Help::Upgrading>.

This L<Statocles::App|Statocles::App> manages static content with no processing,
perfect for images, stylesheets, scripts, or already-built HTML.

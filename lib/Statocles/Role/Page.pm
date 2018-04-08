package Statocles::Role::Page;
our $VERSION = '0.094';
# ABSTRACT: Base role for rendering files

use Statocles::Base 'Role';
with 'Statocles::Role::PageAttrs';
use Statocles::Template;
use Mojo::DOM;

=attr site

The site this page is part of.

=cut

has site => (
    is => 'ro',
    isa => InstanceOf['Statocles::Site'],
    lazy => 1,
    default => sub { $Statocles::SITE },
);

=attr app

The application this page came from, so we can give it to the templates.

=cut

has app => (
    is => 'ro',
    isa => ConsumerOf['Statocles::Role::App'],
);

=attr path

The absolute URL path to save this page to.

=cut

has path => (
    is => 'rw',
    isa => PagePath,
    coerce => PagePath->coercion,
    required => 1,
);

=attr type

The MIME type of this page. By default, will use the L<path's|/path> file extension
to detect a likely type.

=cut

our %TYPES = (
    # text
    html => 'text/html',
    markdown => 'text/markdown',
    css => 'text/css',

    # image
    jpg => 'image/jpeg',
    jpeg => 'image/jpeg',
    png => 'image/png',
    gif => 'image/gif',

    # application
    rss => 'application/rss+xml',
    atom => 'application/atom+xml',
    js => 'application/javascript',
    json => 'application/json',
);

has type => (
    is => 'ro',
    isa => Str,
    lazy => 1,
    default => sub {
        my ( $self ) = @_;
        my $filename = (split '/', $self->path.'', -1)[-1];
        return $TYPES{html} if $filename eq '';
        my ( $ext ) = $filename =~ /[.]([^.]+)$/;
        return $TYPES{ $ext };
    },
);

=attr date

The date of this page. Used for last updated date and blog post dates.

=cut

has date => (
    is => 'rw',
    isa => DateTimeObj,
    coerce => DateTimeObj->coercion,
    lazy => 1,
    default => sub { DateTime::Moonpig->now( time_zone => 'local' ) },
);

=attr data

A hash of additional template variables for this page.

=cut

# XXX: For now this is the only way to add arbitrary template vars to
# the page. In the Statocles::Page::Document class, it defaults to the
# data attribute of the Document object. I suspect this might create
# a conflict when both the document and the application need to add
# arbitrary template variables. If that happens, we will require a new,
# application-only attribute.
has data => (
    is => 'ro',
    isa => HashRef,
    default => sub { {} },
);

=attr markdown

The markdown object to render document Markdown. Defaults to L<the markdown
attribute from the Site object|Statocles::Site/markdown>.

Any object with a "markdown" method will work.

=cut

has markdown => (
    is => 'rw',
    isa => HasMethods['markdown'],
    default => sub { $_[0]->site->markdown },
);

=attr template

The main L<template|Statocles::Template> for this page. The result will be
wrapped in the L<layout template|/layout>.

=cut

my @template_attrs = (
    is => 'rw',
    isa => InstanceOf['Statocles::Template'],
    coerce => Statocles::Template->coercion,
    default => sub {
        Statocles::Template->new( content => '<%= content %>' ),
    },
);

has template => @template_attrs;

=attr layout

The layout L<template|Statocles::Template> for this page, which will wrap the content generated by the
L<template|/template>.

=cut

has layout => @template_attrs;

=attr search_change_frequency

How frequently a search engine should check this page for changes. This is used
in the L<sitemap.xml|http://www.sitemaps.org> to give hints to search engines.

Should be one of:

    always
    hourly
    daily
    weekly
    monthly
    yearly
    never

Defaults to C<weekly>.

B<NOTE:> This is only a hint to search engines, not a command. Pages marked C<hourly>
may be checked less often, and pages marked C<never> may still be checked once in a
while. C<never> is mainly used for archived pages or permanent links.

=cut

has search_change_frequency => (
    is => 'rw',
    isa => Enum[qw( always hourly daily weekly monthly yearly never )],
    default => sub { 'weekly' },
);

=attr search_priority

How high should this page rank in search results compared to similar pages on
this site?  This is used in the L<sitemap.xml|http://www.sitemaps.org> to rank
individual, full pages more highly than aggregate, list pages.

Value should be between C<0.0> and C<1.0>. The default is C<0.5>.

This is only used to decide which pages are more important for the search
engine to crawl, and which pages within your site should be given to users. It
does not improve your rankings compared to other sites. See L<the sitemap
protocol|http://sitemaps.org> for details.

=cut

has search_priority => (
    is => 'rw',
    isa => Num,
    default => sub { 0.5 },
);

# _content_sections
#
# The saved content sections from any rendered content templates. This
# is private for now. We might make this public later
has _content_sections => (
    is => 'rw',
    isa => HashRef,
    default => sub { {} },
);

=attr dom

A L<Mojo::DOM> object containing the HTML DOM of the rendered content for
this page. Any edits made to this object will be reflected in the file
written.

Editing this DOM object is the recommended way to edit pages.

=cut

has dom => (
    is => 'ro',
    isa => InstanceOf['Mojo::DOM'],
    lazy => 1,
    default => sub { Mojo::DOM->new( shift->render ) },
);

=method has_dom

Returns true if the page can render a DOM

=cut

sub has_dom { 1 }

=method vars

    my %vars = $page->vars;

Get extra template variables for this page

=cut

sub vars {
    my ( $self ) = @_;
    return (
        app => $self->app,
        site => $self->site,
        self => $self,
        page => $self,
    );
}

=method render

    my $html = $page->render( %vars );

Render the page, using the L<template|Statocles::Role::Page/template> and wrapping
with the L<layout|Statocles::Role::Page/layout>. Give any extra C<%vars> to the
template, layout, and page C<content> method (if applicable).

The result of this method is cached.

=cut

sub render {
    my ( $self ) = @_;

    $self->site->log->debug( 'Render page: ' . $self->path );

    my %vars = (
        %{ $self->data },
        $self->vars,
    );

    my %tmpl_vars = (
        # XXX: This is suboptimal. Isn't vars() enough?
        ( $self->can( 'content' ) ? ( content => $self->content( %vars ) ) : () ),
        %vars,
    );

    my $content = $self->template->render( %tmpl_vars );

    my $html = $self->layout->render(
        content => $content,
        %vars,
    );

    return $html;
}

=method basename

    my $name = $page->basename;

Get the base file name of this page. Everything after the last C</>.

=cut

sub basename {
    my ( $self ) = @_;
    return $self->path->[-1];
}

=method dirname

    my $dir = $page->dirname;

Get the full directory to this page. Anything that isn't part of L</basename>.

There will not be a trailing slash unless it is the root directory.

=cut

sub dirname {
    my ( $self ) = @_;
    my $clone = $self->path->clone;
    pop @$clone;
    return $clone.'';
}

1;
__END__

=head1 DESCRIPTION

A Statocles::Role::Page takes one or more L<documents|Statocles::Document> and
renders them into one or more HTML pages using a main L<template|/template>
and a L<layout template|/layout>.

=head1 SEE ALSO

=over

=item L<Statocles::Page::Document>

A page that renders a single document.

=item L<Statocles::Page::List>

A page that renders a list of other pages.

=back

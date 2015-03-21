package Statocles::Page;
# ABSTRACT: Render documents into HTML

use Statocles::Base 'Role';
use Statocles::Template;

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
    isa => ConsumerOf['Statocles::App'],
);

=attr path

The absolute URL path to save this page to.

=cut

has path => (
    is => 'rw',
    isa => Path,
    coerce => Path->coercion,
    required => 1,
);

=attr date

The date of this page. Used for last updated date and blog post dates.

=cut

has date => (
    is => 'ro',
    isa => InstanceOf['Time::Piece'],
    lazy => 1,
    default => sub { Time::Piece->new },
);

=attr links

A hash of arrays of links to pages related to this page. Possible keys:

    feed        - Feed pages related to this page
    alternate   - Alternate versions of this page posted to other sites

Each item in the array is a L<link object|Statocles::Link>. The most common
attributes are:

    text        - The text of the link
    href        - The page for the link
    type        - The MIME type of the link, optional

=cut

has _links => (
    is => 'ro',
    isa => LinkHash,
    lazy => 1,
    default => sub { +{} },
    coercion => LinkHash->coercion,
    init_arg => 'links',
);

=attr markdown

The markdown object to render document Markdown. Defaults to L<the markdown
attribute from the Site object|Statocles::Site/markdown>.

Any object with a "markdown" method will work.

=cut

has markdown => (
    is => 'ro',
    isa => HasMethods['markdown'],
    default => sub { $_[0]->site->markdown },
);

=attr template

The main L<template|Statocles::Template> for this page. The result will be
wrapped in the L<layout template|/layout>.

=cut

my @template_attrs = (
    is => 'ro',
    isa => InstanceOf['Statocles::Template'],
    coerce => Statocles::Template->coercion,
    default => sub {
        Statocles::Template->new( content => '<%= $content %>' ),
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
    is => 'ro',
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
    is => 'ro',
    isa => Num,
    default => sub { 0.5 },
);

=method vars

Get extra template variables for this page

=cut

sub vars { }

=method render

Render the page, using the L<template|Statocles::Page/template> and wrapping
with the L<layout|Statocles::Page/layout>.

=cut

sub render {
    my ( $self, %args ) = @_;
    my %vars = (
        %args,
        self => $self,
        app => $self->app,
        $self->vars,
    );

    my $content = $self->template->render(
        ( $self->can( 'content' ) ? ( content => $self->content( %vars ) ) : () ),
        %vars,
    );

    return $self->layout->render(
        content => $content,
        %vars,
    );
}

=method links( KEY )

Get the links set for the given key. See L<the links attribute|/links> for some
commonly-used keys. Returns a list of L<link objects|Statocles::Link>.

=cut

sub links {
    my ( $self, $name ) = @_;
    return $self->_links->{ $name } ? @{ $self->_links->{ $name } } : ();
}

1;
__END__

=head1 DESCRIPTION

A Statocles::Page takes one or more L<documents|Statocles::Document> and
renders them into one or more HTML pages using a main L<template|/template>
and a L<layout template|/layout>.

=head1 SEE ALSO

=over

=item L<Statocles::Page::Document>

A page that renders a single document.

=item L<Statocles::Page::List>

A page that renders a list of other pages.

=back


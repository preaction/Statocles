package Statocles::Theme;
our $VERSION = '0.094';
# ABSTRACT: Templates, headers, footers, and navigation

use Statocles::Base 'Class';
use File::Share qw( dist_dir );
use Scalar::Util qw( blessed );
use Statocles::Template;
with 'Statocles::App';

=attr url_root

The root URL for this application. Defaults to C</theme>.

=cut

has '+url_root' => ( default => sub { '/theme' } );

=attr path

The path to the theme. Can be a string that starts with C<::> to pick a default theme.
Included bundled default themes are:

=over

=item default

A clean default theme. Good for starting your own theme.

=item bootstrap

A theme using Bootstrap 3.

=back

=cut

has path => (
    is => 'ro',
    isa => Path,
    default => sub { Path->coercion->( 'theme' ) },
    coerce => Path->coercion,
);

=attr include_paths

An array of paths to look for includes. The L</path> is added at the end
of this list.

=cut

has include_paths => (
    is => 'ro',
    isa => ArrayRef[Path],
    default => sub { [] },
    coerce => sub {
        my ( $thing ) = @_;
        if ( ref $thing eq 'ARRAY' ) {
            return [ map { Path->coercion->( $_ ) } @$thing ];
        }
        return [ Path->coercion->( $thing ) ];
    },
);

=attr tag_start

String that indicates the start of a template tag. Defaults to
C<< <% >>.

=attr tag_end

String that indicates the end of a template tag. Defaults to C<< %> >>.

=attr line_start

String that indicates the start of a line of template code.
Defaults to C<%>.

=attr expression_mark

String that indicates an expression to be evaluated and inserted into
the template. Defaults to C<=>.

=attr escape_mark

String that escapes the template directives. Defaults to C<%>.

=attr comment_mark

String that indicates a comment. Defaults to C<#>.

=attr capture_start

Keyword that starts capturing string. Defaults to C<begin>.

=attr capture_end

Keyword that ends capturing string. Defaults to C<end>.

=attr trim_mark

String that indicates that whitespace should be trimmed. Defaults to
C<=>.

=cut

has [qw(
    tag_start tag_end
    line_start trim_mark
    replace_mark expression_mark
    escape_mark comment_mark
    capture_start capture_end
)] => (
    is => 'ro',
    isa => Maybe[Str],
);

=attr _templates

The cached template objects for this theme.

=cut

has '+_templates' => (
    is => 'ro',
    isa => HashRef[InstanceOf['Statocles::Template']],
    default => sub { {} },
    lazy => 1,  # Must be lazy or the clearer won't re-init the default
    clearer => '_clear_templates',
);

=attr _includes

The cached template objects for the includes.

=cut

has _includes => (
    is => 'ro',
    isa => HashRef[InstanceOf['Statocles::Template']],
    default => sub { {} },
    lazy => 1,  # Must be lazy or the clearer won't re-init the default
    clearer => '_clear_includes',
);

# The helpers added to this theme.
has _helpers => (
    is => 'ro',
    isa => HashRef[CodeRef],
    default => sub { {} },
    init_arg => 'helpers', # Allow initialization via config file
);

# If true, add the files in the path
has _add_path_files => (
    is => 'ro',
    default => sub { 0 },
);

=method BUILDARGS

Handle the path :: share theme.

=cut

around BUILDARGS => sub {
    my ( $orig, $self, @args ) = @_;
    my $args = $self->$orig( @args );
    if ( $args->{store} ) {
        $args->{path} = delete $args->{store};
    }
    if ( $args->{path} && !ref $args->{path} && $args->{path} =~ /^::/ ) {
        my $name = substr $args->{path}, 2;
        $args->{path} = Path::Tiny->new( dist_dir( 'Statocles' ) )->child( 'theme', $name );
        $args->{_add_path_files} = 1;
    }
    if ( $args->{include_stores} ) {
        $args->{include_paths} = delete $args->{include_stores};
    }
    return $args;
};

=method read

    my $tmpl = $theme->read( $path )

Read the template for the given C<path> and create the
L<template|Statocles::Template> object.

=cut

sub read {
    my ( $self, $path ) = @_;
    $path .= '.ep';

    my $content = eval { $self->path->child( $path )->slurp_utf8; };
    if ( $@ ) {
        if ( blessed $@ && $@->isa( 'Path::Tiny::Error' ) && $@->{op} =~ /^open/ ) {
            die sprintf 'ERROR: Template "%s" does not exist in theme directory "%s"' . "\n",
                $path, $self->path;
        }
        else {
            die $@;
        }
    }

    return $self->build_template( $path, $content );
}

=method build_template

    my $tmpl = $theme->build_template( $path, $content  )

Build a new L<Statocles::Template> object with the given C<path> and C<content>.

=cut

sub build_template {
    my ( $self, $path, $content ) = @_;

    return Statocles::Template->new(
        path => $path,
        content => $content,
        theme => $self,
    );
}

=method template

    my $tmpl = $theme->template( $path )
    my $tmpl = $theme->template( @path_parts )

Get the L<template|Statocles::Template> at the given C<path>, or with the
given C<path_parts>.

=cut

sub template {
    my ( $self, @path ) = @_;
    my $path = Path::Tiny->new( @path );
    return $self->_templates->{ $path } ||= $self->read( $path );
}

=method include

    my $tmpl = $theme->include( $path );
    my $tmpl = $theme->include( @path_parts );

Get the desired L<template|Statocles::Template> to include based on the given
C<path> or C<path_parts>. Looks through all the
L<include_paths|/include_paths> before looking in the L<main path|/path>.

=cut

sub include {
    my ( $self, @path ) = @_;
    my $render = 1;
    if ( $path[0] eq '-raw' ) {
        # Allow raw files to not be passed through the template renderer
        # This override flag will always exist, but in the future we may
        # add better detection to possible file types to process
        $render = 0;
        shift @path;
    }
    my $path = Path::Tiny->new( @path );

    my @search_paths = ( @{ $self->include_paths }, $self->path );
    for my $search_path ( @search_paths ) {
        if ( $search_path->child( $path )->is_file ) {
            if ( $render ) {
                return $self->_includes->{ $path } ||= $self->build_template(
                    $path, $search_path->child( $path )->slurp_utf8,
                );
            }
            return $search_path->child( $path )->slurp_utf8;
        }
    }

    die qq{Can not find include "$path" in include directories: }
        . join( ", ", map { sprintf q{"%s"}, $_ } @search_paths )
        . "\n";
}

=method helper

    $theme->helper( $name, $sub );

Register a helper on this theme. Helpers are functions that are added to
the template to allow for additional features. Helpers are usually added
by L<Statocles plugins|Statocles::Plugin>.

There are a L<default set of helpers available to all
templates|Statocles::Template/DEFAULT HELPERS> which cannot be
overridden by this method.

=cut

sub helper {
    my ( $self, $name, $sub ) = @_;
    $self->_helpers->{ $name } = $sub;
    return;
}

=method clear

    $theme->clear;

Clear out the cached templates and includes. Used by the daemon when it
detects a change to the theme files.

=cut

sub clear {
    my ( $self ) = @_;
    $self->_clear_templates;
    $self->_clear_includes;
    return;
}

=method pages

Get the extra, non-template files to deploy with the rest of the site, like CSS,
JavaScript, and images.

Templates, files that end in C<.ep>, will not be deployed with the rest of the
site.

=cut

sub pages {
    my ( $self, $pages, %args ) = @_;

    my %has = map { $_->path => 1 } @$pages;

    # Find extra files in the main path to add
    my @files;
    my $iter = $self->path->iterator({ recurse => 1 });
    while ( my $path = $iter->() ) {
        next if !$path->is_file;
        next if $path =~ /[.]ep$/;
        next if $has{ $path }++;
        #; say "Theme file path: $path";
        my $rel_path = Path::Tiny->new( $self->url_root, $path->relative( $self->path ) );
        push @files, Statocles::Page::File->new(
            site => $self->site,
            path => $rel_path->stringify,
            file_path => $path,
        );
    }

    #; say "Found pages: " . join ', ', map { $_->path } @files;
    return @files;
};

1;
__END__

=head1 SYNOPSIS

    # Template directory layout
    /theme/site/layout.html.ep
    /theme/site/include/layout.html.ep
    /theme/blog/index.html.ep
    /theme/blog/post.html.ep

    my $theme      = Statocles::Theme->new( path => '/theme' );
    my $layout     = $theme->template( qw( site include layout.html ) );
    my $blog_index = $theme->template( blog => 'index.html' );
    my $blog_post  = $theme->template( 'blog/post.html' );

    # Clear out cached templates and includes
    $theme->clear;

=head1 DESCRIPTION

A Theme contains all the L<templates|Statocles::Template> that
L<applications|Statocles::App> need. This class handles finding and parsing
files into L<template objects|Statocles::Template>.

When the L</path> is read, the templates inside are organized based on
their name and their parent directory.

=head1 SEE ALSO

=over 4

=item L<Statocles::Help::Theme>

=item L<Statocles::Template>

=back

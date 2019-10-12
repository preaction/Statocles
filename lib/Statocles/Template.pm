package Statocles::Template;
our $VERSION = '0.096';
# ABSTRACT: A template object to pass around

use Statocles::Base 'Class';
use Mojo::Template;
use Scalar::Util qw( blessed );
use Storable qw( dclone );

=attr content

The main template string. This will be generated by reading the file C<path> by
default.

=cut

has content => (
    is => 'ro',
    isa => Str,
    lazy => 1,
    default => sub {
        my ( $self ) = @_;
        return Path::Tiny->new( $self->path )->slurp;
    },
);

=attr path

The path to the file for this template. Optional.

=cut

has path => (
    is => 'ro',
    isa => Str,
    coerce => sub {
        return "$_[0]"; # Force stringify in case of Path::Tiny objects
    },
);

=attr theme

The theme this template was created from. Used for includes and other
information.

=cut

has theme => (
    is => 'ro',
    isa => ThemeType,
    coerce => ThemeType->coercion,
);

=attr include_stores

An array of L<stores|Statocles::Store> to look for includes. Will be
used in addition to the L<include_stores from the
Theme|Statocles::Theme/include_stores>.

=cut

has include_stores => (
    is => 'ro',
    isa => ArrayRef[StoreType],
    default => sub { [] },
    coerce => sub {
        my ( $thing ) = @_;
        if ( ref $thing eq 'ARRAY' ) {
            return [ map { StoreType->coercion->( $_ ) } @$thing ];
        }
        return [ StoreType->coercion->( $thing ) ];
    },
);

has _template => (
    is => 'ro',
    isa => InstanceOf['Mojo::Template'],
    lazy => 1,
    default => sub {
        my ( $self ) = @_;
        my %config;
        if ( $self->theme ) {
            %config = map { $_ => $self->theme->$_ }
                grep { $self->theme->$_ }
                qw(
                    tag_start tag_end
                    line_start trim_mark
                    replace_mark expression_mark
                    escape_mark comment_mark
                    capture_start capture_end
                );
        }
        my $t = Mojo::Template->new(
            name => $self->path,
            %config,
        );
        $t->parse( $self->content );
        return $t;
    },
);

=method BUILDARGS

Set the default path to something useful for in-memory templates.

=cut

around BUILDARGS => sub {
    my ( $orig, $self, @args ) = @_;
    my $args = $self->$orig( @args );
    if ( !$args->{path} ) {
        my ( $i, $caller_class ) = ( 0, (caller 0)[0] );
        while ( $caller_class->isa( 'Statocles::Template' )
            || $caller_class->isa( 'Sub::Quote' )
            || $caller_class->isa( 'Method::Generate::Constructor' )
        ) {
            #; say "Class: $caller_class";
            $i++;
            $caller_class = (caller $i)[0];
        }
        #; say "Class: $caller_class";
        $args->{path} = join " line ", (caller($i))[1,2];
    }
    return $args;
};

=method render

    my $html = $tmpl->render( %args )

Render this template, passing in %args. Each key in %args will be available as
a scalar in the template.

=cut

sub render {
    my ( $self, %args ) = @_;
    my $t = $self->_template;
    $t->prepend( $self->_prelude( '_tmpl', keys %args ) );

    my $content;
    {
        # Add the helper subs, like Mojolicious::Plugin::EPRenderer does
        no strict 'refs';
        no warnings 'redefine';

        # Add theme helpers first, to ensure default helpers do not get
        # overridden.
        if ( $self->theme ) {
            my %theme_helpers = %{ $self->theme->_helpers };
            for my $helper ( keys %theme_helpers ) {
                *{"@{[$t->namespace]}::$helper"} = sub {
                    $theme_helpers{ $helper }->( \%args, @_ );
                };
            }
        }

        # Add default helpers
        local *{"@{[$t->namespace]}::include"} = sub {
            if ( $_[0] eq '-raw' ) {
                return $self->include( @_ );
            }
            my ( $name, %extra_args ) = @_;
            my $inner_tmpl = $self->include( $name );
            return $inner_tmpl->render( %args, %extra_args ) || '';
        };

        local *{"@{[$t->namespace]}::markdown"} = sub {
            my ( $text, %extra_args ) = @_;
            die "Cannot use markdown helper: No site object given to template"
                unless exists $args{site};
            return $args{site}->markdown->markdown( ref $text eq 'CODE' ? $text->() : $text );
        };

        local *{"@{[$t->namespace]}::content"} = sub {
            my ( $section, $content ) = @_;
            if ( $content ) {
                if ( ref $content eq 'CODE' ) {
                    $content = $content->();
                }
                $args{page}->_content_sections->{ $section } = $content;
                return;
            }
            elsif ( $section ) {
                return $args{page}->_content_sections->{ $section } // '';
            }
            return $args{content};
        };

        $content = eval { $t->process( \%args ) };
    }

    if ( blessed $content && $content->isa( 'Mojo::Exception' ) ) {
        die "Error in template: " . $content;
    }
    return $content;
}

# Build the Perl string that will unpack the passed-in args
# This is how Mojolicious::Plugin::EPRenderer does it, but I'm probably
# doing something wrong here...
sub _prelude {
    my ( $self, @vars ) = @_;
    return join " ",
        'use strict; use warnings; no warnings "ambiguous";',
        'my $vars = shift;',
        map( { "my \$$_ = \$vars->{'$_'};" } @vars ),
        ;
}

=method include

    my $tmpl = $tmpl->include( $path );
    my $tmpl = $tmpl->include( @path_parts );

Get the desired L<template|Statocles::Template> to include based on the given
C<path> or C<path_parts>. Looks through all the L<include_stores|/include_stores>.
If nothing is found, looks in the L<theme includes|Statocles::Theme/include>.

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

    my @stores = @{ $self->include_stores };
    for my $store ( @{ $self->include_stores } ) {
        if ( $store->has_file( $path ) ) {
            if ( $render ) {
                return $self->theme->build_template(
                    $path, $store->path->child( $path )->slurp_utf8,
                );
            }
            return $store->path->child( $path )->slurp_utf8;
        }
    }

    my $include = eval {
        $self->theme->include( !$render ? ( '-raw', @path ) : @path );
    };
    if ( $@ && $@ =~ /^Can not find include/ ) {
        die qq{Can not find include "$path" in include directories: }
            . join( ", ", map { sprintf q{"%s"}, $_->path } @stores, @{ $self->theme->include_stores }, $self->theme->store )
            . "\n";
    }

    return $include;
}

=method merge_state

    $tmpl->merge_state( $state );

Merge the given C<$state> hash reference into the existing. Keys
in C<$state> override those in L<the state attribute|/state>.

=cut

sub merge_state {
    my ( $self, $new_state ) = @_;
    for my $key ( keys %$new_state ) {
        my $value = $new_state->{ $key };
        $value = dclone $value if ref $value;
        $self->state->{ $key } = $value;
    }
    return;
}

=method coercion

    my $coerce = Statocles::Template->coercion;

    has template => (
        is => 'ro',
        isa => InstanceOf['Statocles::Template'],
        coerce => Statocles::Template->coercion,
    );

A class method to returns a coercion sub to convert strings into template
objects.

=cut

sub coercion {
    my ( $class ) = @_;
    return sub {
        die "Template is undef" unless defined $_[0];
        return !ref $_[0]
            ? Statocles::Template->new( content => $_[0] )
            : $_[0]
            ;
    };
}

1;
__END__

=head1 DESCRIPTION

This is the template abstraction layer for Statocles.

=head1 TEMPLATE LANGUAGE

The default Statocles template language is Mojolicious's Embedded Perl
template. Inside the template, every key of the %args passed to render() will
be available as a simple scalar:

    # template.tmpl
    % for my $p ( @$pages ) {
    <%= $p->{content} %>
    % }

    my $tmpl = Statocles::Template->new( path => 'template.tmpl' );
    $tmpl->render(
        pages => [
            { content => 'foo' },
            { content => 'bar' },
        ]
    );

=head1 DEFAULT HELPERS

The following functions are available to the template by default.

=head2 content

The content helper gets and sets content sections, including the main content.

    %= content
    <%= content %>

With no arguments, C<content> will get the main content of the template.
This will be the HTML from the document or page.

    % content section_name => begin
        Section Content
    % end
    <% content section_name => "Section Content" %>

With two arguments, save the content into the named section. This will
be saved in the template L<state attribute|/state>, which can be copied
to other templates (like the layout template).

    %= content 'section_name'
    <%= content 'section_name' %>

With one argument, gets the content previously stored with the given
section name. This comes from L<the state attribute|/state>.

=head2 include

    %= include 'path/file.html.ep'
    %= include 'path/file.markdown', var => 'value'

Include a file into this one. The file will be parsed as a template and
given the same variables as the current template. Optionally, additional
name-value pairs can be given to the included template. These additional
template variables override any current variables.

Includes will be searched for in the L<Theme's C<include_stores>
attribute|Statocles::Theme/include_stores>. For content documents
rendered by the L<Statocles::Page::Document
class|Statocles::Page::Document>, this includes the document's parent
directory.

Including markdown files does not automatically translate them into
HTML. If you're in a page template or layout template, use the
L<markdown helper|/markdown> to render the markdown into HTML.

=head2 markdown

    %= markdown $markdown_text
    %= markdown $app->{data}{description}
    %= markdown include 'path/include.markdown'

Render the given markdown text into HTML. This is useful for allowing users to
write markdown in L<site data|Statocles::Site/data>, and L<app data|Statocles::App/data> in
the L<configuration file|Statocles::Help::Config/data>,
or L<document data|Statocles::Document/data> attributes in the document frontmatter.

Combining the C<markdown> and L<include|/include> helpers allows for adding
template directives to any included markdown file.

=head1 SEE ALSO

=over 4

=item L<Statocles::Help::Theme>

=item L<Statocles::Theme>

=back

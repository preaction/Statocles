package Statocles::App::Blog;
our $VERSION = '0.094';
# ABSTRACT: A blog application

use Text::Unidecode;
use Statocles::Base 'Class';
use Getopt::Long qw( GetOptionsFromArray );
use Statocles::Document;
use Statocles::Page::Document;
use Statocles::Page::List;
use Statocles::Util qw( run_editor read_stdin );

with 'Statocles::Role::App::Store';

=attr store

    # site.yml
    blog:
        class: Statocles::App::Blog
        args:
            store: _posts

The L<store directory path|Statocles::Store> to read for blog posts. Required.

The Blog directory is organized in a tree by date, with a directory for the
year, month, day, and post. Each blog post is its own directory to allow for
additional files for the post, like images or additional pages.

=cut

=attr tag_text

    # site.yml
    blog:
        class: Statocles::App::Blog
        args:
            tag_text:
                software: Posts about software and development
                travel: My travelogue around the world!

A hash of tag and introductory Markdown that will be shown on the tag's main
page. Having a description is optional.

Using L<Beam::Wire's $config directive|Beam::Wire/Config Services>, you can
put the tag text in an external file:

    # site.yml
    blog:
        class: Statocles::App::Blog
        args:
            tag_text:
                $config: tags.yml

    # tags.yml
    software: |-
        # Software

        Posts about software development, mostly in [Perl](http://perl.org)

    travel: |-
        # Travel

        My travelogue around the world! [Also visit my Instagram!](http://example.com)

=cut

has tag_text => (
    is => 'ro',
    isa => HashRef,
    default => sub { {} },
);

=attr page_size

    # site.yml
    blog:
        class: Statocles::App::Blog
        args:
            page_size: 5

The number of posts to put in a page (the main page and the tag pages). Defaults
to 5.

=cut

has page_size => (
    is => 'ro',
    isa => Int,
    default => sub { 5 },
);

=attr index_tags

    # site.yml
    blog:
        class: Statocles::App::Blog
        args:
            index_tags: [ '-private', '+important' ]

Filter the tags shown in the index page. An array of tags prefixed with either
a + or a -. By prefixing the tag with a "-", it will be removed from the index,
unless a later tag prefixed with a "+" also matches.

By default, all tags are shown on the index page.

So, given a document with tags "foo", and "bar":

    index_tags: [ ]                 # document will be included
    index_tags: [ '-foo' ]          # document will not be included
    index_tags: [ '-foo', '+bar' ]  # document will be included

=cut

has index_tags => (
    is => 'ro',
    isa => ArrayRef[Str],
    default => sub { [] },
);

=attr template_dir

The directory (inside the theme directory) to use for this app's templates.
Defaults to C<blog>.

=cut

has '+template_dir' => (
    default => 'blog',
);

# A cache of the last set of post pages we have
# XXX: We need to allow apps to have a "clear" the way that Store and Theme do
has _post_pages => (
    is => 'rw',
    isa => ArrayRef,
    predicate => '_has_cached_post_pages',
);

# The default post information hash
has _default_post => (
    is => 'rw',
    isa => HashRef,
    lazy => 1,
    default => sub {
        {
            tags => undef,
            content => "Markdown content goes here.\n",
        }
    },
);

=method command

    my $exitval = $app->command( $app_name, @args );

Run a command on this app. The app name is used to build the help, so
users get exactly what they need to run.

=cut

my $USAGE_INFO = <<'ENDHELP';
Usage:
    $name help -- This help file
    $name post [--date YYYY-MM-DD] <title> -- Create a new blog post with the given title
ENDHELP

sub command {
    my ( $self, $name, @argv ) = @_;

    if ( !$argv[0] ) {
        say STDERR "ERROR: Missing command";
        say STDERR eval "qq{$USAGE_INFO}";
        return 1;
    }

    if ( $argv[0] eq 'help' ) {
        say eval "qq{$USAGE_INFO}";
    }
    elsif ( $argv[0] eq 'post' ) {
        my %opt;
        my @doc_opts = qw(author layout status tags template);
        GetOptionsFromArray( \@argv, \%opt,
            'date:s',
            map { "$_:s" } @doc_opts,
        );

        my $doc;

        # Read post content on STDIN
        if ( my $content = read_stdin() ) {
            $doc = Statocles::Document->parse_content(
                (map { defined $opt{$_} ? ( $_, $opt{$_} ) : () } @doc_opts),
                ( @argv > 1 ? ( title => join( " ", @argv[1..$#argv] ) ) : () ),
                content => $content,
            );
        }
        else {
            $doc = Statocles::Document->new(
                %{ $self->_default_post },
                (map { defined $opt{$_} ? ( $_, $opt{$_} ) : () } @doc_opts),
                ( @argv > 1 ? ( title => join( " ", @argv[1..$#argv] ) ) : () ),
            );
        }

        if ( !$ENV{EDITOR} && !$doc->title ) {
            say STDERR <<"ENDHELP";
Title is required when \$EDITOR is not set.

Usage: $name post <title>
ENDHELP
            return 1;
        }

        my ( $year, $mon, $day );
        if ( $opt{ date } ) {
            ( $year, $mon, $day ) = split /-/, $opt{date};
        }
        else {
            ( undef, undef, undef, $day, $mon, $year ) = localtime;
            $year += 1900;
            $mon += 1;
        }

        my @date_parts = (
            sprintf( '%04i', $year ),
            sprintf( '%02i', $mon ),
            sprintf( '%02i', $day ),
        );

        my $slug = $self->make_slug( $doc->title || "new post" );
        my @partsdir = (@date_parts, $slug);
        my @partsfile = (@partsdir, "index.markdown");
        my $path = Mojo::Path->new->parts(\@partsfile);
        $self->store->write_file( $path => $doc );
        my $full_path = $self->store->path->child( @partsfile );

        if ( my $content = run_editor( $full_path ) ) {
            my $old_title = $doc->title;
            my $doc = Statocles::Document->parse_content(
                path => $path.'',
                store => $self->store,
                content => $content,
            );
            if ( $doc->title ne $old_title ) {
                $self->store->path->child( @partsdir )->remove_tree;
                $slug = $self->make_slug( $doc->title || "new post" );
                @partsdir = (@date_parts, $slug);
                @partsfile = (@partsdir, "index.markdown");
                $path = Mojo::Path->new->parts(\@partsfile);
                $self->store->write_file( $path => $doc );
                $full_path = $self->store->path->child( @partsfile );
            }
        }

        say "New post at: $full_path";

    }
    else {
        say STDERR qq{ERROR: Unknown command "$argv[0]"};
        say STDERR eval "qq{$USAGE_INFO}";
        return 1;
    }

    return 0;
}

=method make_slug

    my $slug = $app->make_slug( $title );

Given a post title, remove special characters to create a slug.

=cut

sub make_slug {
    my ( $self, $slug ) = @_;
    $slug = unidecode($slug);
    $slug =~ s/'//g;
    $slug =~ s/[\W]+/-/g;
    $slug =~ s/^-|-$//g;
    return lc $slug;
}

=method index

    my @pages = $app->index( \@post_pages );

Build the index page (a L<list page|Statocles::Page::List>) and all related
feed pages out of the given array reference of post pages.

=cut

my %FEEDS = (
    rss => {
        text => 'RSS',
        template => 'index.rss',
    },
    atom => {
        text => 'Atom',
        template => 'index.atom',
    },
);

sub index {
    my ( $self, $all_post_pages ) = @_;

    my @index_tags;
    my %tag_flag;
    for my $tag_spec ( map lc, @{ $self->index_tags } ) {
        my $tag = substr $tag_spec, 1;
        push @index_tags, $tag;
        $tag_flag{$tag} = substr $tag_spec, 0, 1;
    }

    my @index_post_pages;
    PAGE: for my $page ( @$all_post_pages ) {
        my $page_flag = '+';
        my %page_tags;
        @page_tags{ map lc, @{ $page->document->tags } } = 1; # we use exists(), so value doesn't matter
        for my $tag ( map lc, @index_tags ) {
            if ( exists $page_tags{ $tag } ) {
                $page_flag = $tag_flag{ $tag };
            }
        }
        push @index_post_pages, $page if $page_flag eq '+';
    }

    my @pages = Statocles::Page::List->paginate(
        after => $self->page_size,
        path => $self->url( 'page/%i/index.html', 1 ),
        index => $self->url( 'index.html' ),
        pages => [ _sort_page_list( @index_post_pages ) ],
        app => $self,
        template => $self->template( 'index.html' ),
        layout => $self->template( 'layout.html' ),
    );

    return unless @pages; # Only build feeds if we have pages

    my $index = $pages[0];
    my @feed_pages;
    my @feed_links;
    for my $feed ( sort keys %FEEDS ) {
        my $page = Statocles::Page::List->new(
            app => $self,
            pages => $index->pages,
            path => $self->url( 'index.' . $feed ),
            template => $self->template( $FEEDS{$feed}{template} ),
            links => {
                alternate => [
                    $self->link(
                        href => $index->path,
                        title => 'index',
                        type => $index->type,
                    ),
                ],
            },
        );

        push @feed_pages, $page;
        push @feed_links, $self->link(
            text => $FEEDS{ $feed }{ text },
            href => $page->path.'',
            type => $page->type,
        );
    }

    # Add the feeds to all the pages
    for my $page ( @pages ) {
        $page->links( feed => @feed_links );
    }

    return ( @pages, @feed_pages );
}

=method tag_pages

    my @pages = $app->tag_pages( \%tag_pages );

Get L<pages|Statocles::Role::Page> for the tags in the given blog post documents
(build from L<the post_pages method|/post_pages>, including relevant feed
pages.

=cut

sub tag_pages {
    my ( $self, $tagged_docs ) = @_;

    my @pages;
    for my $tag ( keys %$tagged_docs ) {
        my $tagroot = $self->url( join "/", 'tag', $self->_tag_url( $tag ) );
        my @tag_pages = Statocles::Page::List->paginate(
            after => $self->page_size,
            path => join( "/", $tagroot, 'page/%i/index.html' ),
            index => join( "/", $tagroot, 'index.html' ),
            pages => [ _sort_page_list( @{ $tagged_docs->{ $tag } } ) ],
            app => $self,
            template => $self->template( 'index.html' ),
            layout => $self->template( 'layout.html' ),
            data => {
                tag => $tag,
                tag_text => $self->tag_text->{ $tag },
            },
        );

        my $index = $tag_pages[0];
        my @feed_pages;
        my @feed_links;
        for my $feed ( sort keys %FEEDS ) {
            my $tag_file = $self->_tag_url( $tag ) . '.' . $feed;

            my $page = Statocles::Page::List->new(
                app => $self,
                pages => $index->pages,
                path => $self->url( join( "/", 'tag', $tag_file ) ),
                template => $self->template( $FEEDS{$feed}{template} ),
                links => {
                    alternate => [
                        $self->link(
                            href => $index->path,
                            title => $tag,
                            type => $index->type,
                        ),
                    ],
                },
            );

            push @feed_pages, $page;
            push @feed_links, $self->link(
                text => $FEEDS{ $feed }{ text },
                href => $page->path.'',
                type => $page->type,
            );
        }

        # Add the feeds to all the pages
        for my $page ( @tag_pages ) {
            $page->links( feed => @feed_links );
        }

        push @pages, @tag_pages, @feed_pages;
    }

    return @pages;
}

=method pages

    my @pages = $app->pages( %options );

Get all the L<pages|Statocles::Role::Page> for this application. Available options
are:

=over 4

=item date

The date to build for. Only posts on or before this date will be built.
Defaults to the current date.

=back

=cut

# sub pages
around pages => sub {
    my ( $orig, $self, %opt ) = @_;
    $opt{date} ||= DateTime::Moonpig->now( time_zone => 'local' )->ymd;
    my $root = $self->url_root;
    my $is_dated_path = qr{^$root/?(\d{4})/(\d{2})/(\d{2})/};
    my @parent_pages = $self->$orig( %opt );
    my @pages =
        map { $_->[0] }
        # Only pages today or before
        grep { $_->[1] le $opt{date} }
        # Create the page's date
        map { [ $_, join "-", $_->path =~ $is_dated_path ] }
        # Only dated pages
        grep { $_->path =~ $is_dated_path }
        #$self->$orig( %opt );
        @parent_pages;
    @pages = _sort_page_list( @pages );

    my @post_pages;
    my %tag_pages;

    for my $page ( @pages ) {

        if ( $page->isa( 'Statocles::Page::Document' ) ) {

            if ( $page->path =~ m{$is_dated_path [^/]+ (?:/index)? [.]html$}x ) {
                my ( $year, $month, $day ) = ( $1, $2, $3 );

                push @post_pages, $page;

                my $doc = $page->document;
                $page->date( $doc->has_date ? $doc->date : DateTime::Moonpig->new( year => $year, month => $month, day => $day ) );

                my @tags;
                for my $tag ( @{ $doc->tags } ) {
                    push @{ $tag_pages{ lc $tag } }, $page;
                    push @tags, $self->link(
                        text => $tag,
                        href => join( "/", 'tag', $self->_tag_url( $tag ), '' ),
                    );
                }
                $page->tags( \@tags );

                $page->template( $self->template( 'post.html' ) );
            }
        }
    }

    for ( my $i = 0; $i < @post_pages; $i++ ) {

        my $page = $post_pages[$i];
        my $prev_page = $i ? $post_pages[$i-1] : undef;
        my $next_page = $post_pages[$i+1];
        $page->prev_page( $prev_page ) if $prev_page;
        $page->next_page( $next_page ) if $next_page;
    }

    # Cache the post pages for this build
    # XXX: This needs to be handled more intelligently with proper dependencies
    $self->_post_pages( \@post_pages );

    my @all_pages = ( $self->index( \@post_pages ), $self->tag_pages( \%tag_pages ), @pages );
    return @all_pages;
};

=method tags

    my @links = $app->tags;

Get a set of L<link objects|Statocles::Link> suitable for creating a list of
tag links. The common attributes are:

    text => 'The tag text'
    href => 'The URL to the tag page'

=cut

sub tags {
    my ( $self ) = @_;
    my %tags;
    my @pages = @{ $self->_post_pages || [] };
    for my $page ( @pages ) {
        for my $tag ( @{ $page->document->tags } ) {
            $tags{ lc $tag } ||= $tag;
        }
    }
    return map {; $self->link( text => $_, href => join( "/", 'tag', $self->_tag_url( $_ ), '' ) ) }
        map { $tags{ $_ } }
        sort keys %tags;
}

sub _tag_url {
    my ( $self, $tag ) = @_;
    return lc $self->make_slug( $tag );
}

=method recent_posts

    my @pages = $app->recent_posts( $count, %filter );

Get the last $count recent posts for this blog. Useful for templates and site
index pages.

%filter is an optional set of filters to apply to only show recent posts
matching the given criteria. The following filters are available:

=over 4

=item tags

(string) Only show posts with the given tag

=back

=cut

sub recent_posts {
    my ( $self, $count, %filter ) = @_;

    my $root = $self->url_root;
    my @pages = $self->_has_cached_post_pages ? @{ $self->_post_pages } : $self->pages;
    my @found_pages;
    PAGE: for my $page ( @pages ) {
        next PAGE unless $page->path =~ qr{^$root/?(\d{4})/(\d{2})/(\d{2})/[^/]+(?:/index)?[.]html$};

        QUERY: for my $attr ( keys %filter ) {
            my $value = $filter{ $attr };
            if ( $attr eq 'tags' ) {
                next PAGE unless grep { $_ eq $value } @{ $page->document->tags };
            }
        }

        push @found_pages, $page;
        last if @found_pages >= $count;
    }

    return @found_pages;
}

=method page_url

    my $url = $app->page_url( $page )

Return the absolute URL to this L<page object|Statocles::Role::Page>, removing the
"/index.html" if necessary.

=cut

# XXX This is TERRIBLE. We need to do this better. Perhaps a "url()" helper in the
# template? And a full_url() helper? Or perhaps the template knows whether it should
# use absolute (/whatever) or full (http://www.example.com/whatever) URLs?

sub page_url {
    my ( $self, $page ) = @_;
    my $url = "".$page->path;
    $url =~ s{/index[.]html$}{/};
    return $url;
}

#=sub _sort_list
#
#   my @sorted_pages = _sort_page_list( @unsorted_pages );
#
# Sort a list of blog post pages into buckets according to the date
# component of their path, and then sort the buckets according to the
# date field in the document.
#
# This allows a user to order the posts in a single day themselves,
# predictably and consistently.

sub _sort_page_list {
    return map { $_->[0] }
        sort { $b->[1] cmp $a->[1] || $b->[2] cmp $a->[2] }
        map { [ $_, $_->path =~ m{/(\d{4}/\d{2}/\d{2})}, $_->date ] }
        @_;
}

1;
__END__

=head1 DESCRIPTION

This is a simple blog application for Statocles.

=head2 FEATURES

=over

=item *

Content dividers. By dividing your main content with "---", you create
sections. Only the first section will show up on the index page or in RSS
feeds.

=item *

RSS and Atom syndication feeds.

=item *

Tags to organize blog posts. Tags have their own custom feeds so users can
subscribe to only those posts they care about.

=item *

Cross-post links to redirect users to a syndicated blog. Useful when you
participate in many blogs and want to drive traffic to them.

=item *

Post-dated blog posts to appear automatically when the date is passed. If a
blog post is set in the future, it will not be added to the site when running
C<build> or C<deploy>.

In order to ensure that post-dated blogs get added, you may want to run
C<deploy> in a nightly cron job.

=back

=head1 COMMANDS

=head2 post

    post [--date <date>] <title>

Create a new blog post, optionally setting an initial C<title>. The post will be
created in a directory according to the current date.

Initial post content can be read from C<STDIN>. This lets you write other programs
to generate content for blog posts (for example, to help automate release blog posts).

=head1 THEME

=over

=item index.html

The index page template. Gets the following template variables:

=over

=item site

The L<Statocles::Site> object.

=item pages

An array reference containing all the blog post pages. Each page is a hash reference with the following keys:

=over

=item content

The post content

=item title

The post title

=item author

The post author

=back

=item post.html

The main post page template. Gets the following template variables:

=over

=item site

The L<Statocles::Site> object

=item content

The post content

=item title

The post title

=item author

The post author

=back

=back

=back

=head1 SEE ALSO

=over 4

=item L<Statocles::Role::App>

=back


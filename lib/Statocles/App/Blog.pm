package Statocles::App::Blog;
# ABSTRACT: A blog application

use Statocles::Base 'Class';
use Getopt::Long qw( GetOptionsFromArray );
use Statocles::Store::File;
use Statocles::Theme;
use Statocles::Page::Document;
use Statocles::Page::List;
use Statocles::Page::Feed;

extends 'Statocles::App';

=attr store

The L<store|Statocles::Store> to read for documents.

=cut

has store => (
    is => 'ro',
    isa => Store,
    coerce => Store->coercion,
    required => 1,
);

=attr url_root

The URL root of this application. All pages from this app will be under this
root. Use this to ensure two apps do not try to write the same path.

=cut

has url_root => (
    is => 'ro',
    isa => Str,
    required => 1,
);

=attr theme

The L<theme|Statocles::Theme> for this app. See L</THEME> for what templates this app
uses.

=cut

has theme => (
    is => 'ro',
    isa => Theme,
    required => 1,
    coerce => Theme->coercion,
);

=attr page_size

The number of posts to put in a page (the main page and the tag pages). Defaults
to 5.

=cut

has page_size => (
    is => 'ro',
    isa => Int,
    default => sub { 5 },
);

=attr index_tags

Filter the tags shown in the index page. An array of tags prefixed with either
a + or a -. By prefixing the tag with a "-", it will be removed from the index,
unless a later tag prefixed with a "+" also matches.

By default, all tags are shown on the index page.

So, given a document with tags "foo", and "bar":

    index_tags => [ ];                  # document will be included
    index_tags => [ '-foo' ];           # document will not be included
    index_tags => [ '-foo', '+bar' ];   # document will be included

=cut

has index_tags => (
    is => 'ro',
    isa => ArrayRef[Str],
    default => sub { [] },
);

=method command( app_name, args )

Run a command on this app. The app name is used to build the help, so
users get exactly what they need to run.

=cut

our $default_post = {
    author => undef,
    tags => undef,
    content => <<'ENDCONTENT',
Markdown content goes here.
ENDCONTENT
};

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
        GetOptionsFromArray( \@argv, \%opt,
            'date:s',
        );

        my $title = join " ", @argv[1..$#argv];
        if ( !$ENV{EDITOR} && !$title ) {
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

        my %doc = (
            %$default_post,
            title => $title,
            last_modified => Time::Piece->new,
        );

        # Read post content on STDIN
        if ( !-t *STDIN ) {
            $doc{content} = do { local $/; <STDIN> };
            # Re-open STDIN as the TTY so that the editor (vim) can use it
            # XXX Is this also a problem on Windows?
            if ( -e '/dev/tty' ) {
                close STDIN;
                open STDIN, '/dev/tty';
            }
        }

        if ( $ENV{EDITOR} ) {
            # I can see no good way to test this automatically
            my $tmp_store = Statocles::Store::File->new( path => Path::Tiny->tempdir );
            my $tmp_path = $tmp_store->write_document( new_post => \%doc );
            system $ENV{EDITOR}, $tmp_path;
            %doc = %{ $tmp_store->read_document( 'new_post' ) };
            $title = $doc{title};
        }

        my $slug = lc $title;
        $slug =~ s/\s+/-/g;
        my $path = Path::Tiny->new( @date_parts, "$slug.yml" );
        my $full_path = $self->store->write_document( $path => \%doc );
        say "New post at: $full_path";

    }
    else {
        say STDERR qq{ERROR: Unknown command "$argv[0]"};
        say STDERR eval "qq{$USAGE_INFO}";
        return 1;
    }

    return 0;
}

=method post_pages()

Get the individual post Statocles::Page objects.

=cut

sub post_pages {
    my ( $self ) = @_;
    my $today = Time::Piece->new->ymd;
    my @pages;
    for my $doc ( @{ $self->store->documents } ) {
        my $path = join "/", $self->url_root, $doc->path;
        $path =~ s{/{2,}}{/}g;
        $path =~ s{[.]\w+$}{.html};

        my @date_parts = $path =~ m{/(\d{4})/(\d{2})/(\d{2})/[^/]+$};
        next unless @date_parts;
        my $date = join "-", @date_parts;

        next if $date gt $today;

        my @tags;
        for my $tag ( @{ $doc->tags } ) {
            push @tags, {
                title => $tag,
                href => $self->_tag_url( $tag ),
            };
        }

        push @pages, Statocles::Page::Document->new(
            app => $self,
            layout => $self->theme->template( site => 'layout.html' ),
            template => $self->theme->template( blog => 'post.html' ),
            document => $doc,
            path => $path,
            published => Time::Piece->strptime( $date, '%Y-%m-%d' ),
            tags => \@tags,
        );
    }
    return @pages;
}

=method index()

Get the index page (a L<list page|Statocles::Page::List>) for this application.
This includes all the relevant L<feed pages|Statocles::Page::Feed>.

=cut

my %FEEDS = (
    rss => {
        title => 'RSS',
        type => 'application/rss+xml',
        template => 'index.rss',
    },
    atom => {
        title => 'Atom',
        type => 'application/atom+xml',
        template => 'index.atom',
    },
);

sub index {
    my ( $self, @all_post_pages ) = @_;

    # Filter the index_tags
    my @index_post_pages;
    PAGE: for my $page ( @all_post_pages ) {
        my $add = 1;
        for my $tag_spec ( @{ $self->index_tags } ) {
            my $flag = substr $tag_spec, 0, 1;
            my $tag = substr $tag_spec, 1;
            if ( grep { $_ eq $tag } @{ $page->document->tags } ) {
                $add = $flag eq '-' ? 0 : 1;
            }
        }
        push @index_post_pages, $page if $add;
    }

    my @pages = Statocles::Page::List->paginate(
        after => $self->page_size,
        path => join( "/", $self->url_root, 'page-%i.html' ),
        index => join( "/", $self->url_root, 'index.html' ),
        # Sorting by path just happens to also sort by date
        pages => [ sort { $b->path cmp $a->path } @index_post_pages ],
        app => $self,
        template => $self->theme->template( blog => 'index.html' ),
        layout => $self->theme->template( site => 'layout.html' ),
    );

    my $index = $pages[0];
    my @feed_pages;
    my @feed_links;
    for my $feed ( sort keys %FEEDS ) {
        my $page = Statocles::Page::Feed->new(
            app => $self,
            type => $FEEDS{ $feed }{ type },
            page => $index,
            path => join( "/", $self->url_root, 'index.' . $feed ),
            template => $self->theme->template( blog => $FEEDS{$feed}{template} ),
        );
        push @feed_pages, $page;
        push @feed_links, {
            title => $FEEDS{ $feed }{ title },
            href => $page->path,
            type => $page->type,
        };
    }

    # Add the feeds to all the pages
    for my $page ( @pages ) {
        $page->links->{feed} = \@feed_links;
    }

    return ( @pages, @feed_pages );
}

=method tag_pages()

Get L<pages|Statocles::Page> for the tags in the blog post documents.

=cut

sub tag_pages {
    my ( $self, @post_pages ) = @_;

    my %tagged_docs = $self->_tag_docs( @post_pages );

    my @pages;
    for my $tag ( keys %tagged_docs ) {
        my @tag_pages = Statocles::Page::List->paginate(
            after => $self->page_size,
            path => join( "/", $self->url_root, 'tag', $tag, 'page-%i.html' ),
            index => $self->_tag_url( $tag ),
            # Sorting by path just happens to also sort by date
            pages => [ sort { $b->path cmp $a->path } @{ $tagged_docs{ $tag } } ],
            app => $self,
            template => $self->theme->template( blog => 'index.html' ),
            layout => $self->theme->template( site => 'layout.html' ),
        );

        my $index = $tag_pages[0];
        my @feed_pages;
        my @feed_links;
        for my $feed ( sort keys %FEEDS ) {
            my $tag_file = $tag . '.' . $feed;
            $tag_file =~ s/\s+/-/g;

            my $page = Statocles::Page::Feed->new(
                type => $FEEDS{ $feed }{ type },
                app => $self,
                page => $index,
                path => join( "/", $self->url_root, 'tag', $tag_file ),
                template => $self->theme->template( blog => $FEEDS{$feed}{template} ),
            );
            push @feed_pages, $page;
            push @feed_links, {
                title => $FEEDS{ $feed }{ title },
                href => $page->path,
                type => $page->type,
            };
        }

        # Add the feeds to all the pages
        for my $page ( @tag_pages ) {
            $page->links->{feed} = \@feed_links;
        }

        push @pages, @tag_pages, @feed_pages;
    }

    return @pages;
}

=method pages()

Get all the L<pages|Statocles::Page> for this application.

=cut

sub pages {
    my ( $self ) = @_;
    my @post_pages = $self->post_pages;
    return (
        ( map { $self->$_( @post_pages ) } qw( index tag_pages ) ),
        @post_pages,
    );
}

=method tags()

Get a set of hashrefs suitable for creating a list of tag links. The hashrefs
contain the following keys:

    title => 'The tag text'
    href => 'The URL to the tag page'

=cut

sub tags {
    my ( $self, @post_pages ) = @_;
    my %tagged_docs = $self->_tag_docs( @post_pages );
    return map {; { title => $_, href => $self->_tag_url( $_ ), } }
        sort keys %tagged_docs
}

sub _tag_docs {
    my ( $self, @post_pages ) = @_;
    my %tagged_docs;
    for my $page ( @post_pages ) {
        for my $tag ( @{ $page->document->tags } ) {
            push @{ $tagged_docs{ $tag } }, $page;
        }
    }
    return %tagged_docs;
}

sub _tag_url {
    my ( $self, $tag ) = @_;
    $tag =~ s/\s+/-/g;
    return join "/", $self->url_root, "tag", $tag, "index.html";
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

Crosspost links to redirect users to a syndicated blog. Useful when you
participate in many blogs and want to drive traffic to them.

=item *

Post-dated blog posts to appear automatically when the date is passed. If a
blog post is set in the future, it will not be added to the site when running
C<build> or C<deploy>.

In order to ensure that post-dated blogs get added, you may want to run
C<deploy> in a nightly cron job.

=back

=head1 THEME

=over

=item blog => index

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

=item blog => post

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

=item L<Statocles::App>

=back


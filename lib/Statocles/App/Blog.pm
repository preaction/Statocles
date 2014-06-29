package Statocles::App::Blog;
# ABSTRACT: A blog application

use Statocles::Class;
use Memoize qw( memoize );
use Getopt::Long qw( GetOptionsFromArray );
use Statocles::Page::Document;
use Statocles::Page::List;
use Statocles::Page::Feed;

extends 'Statocles::App';

=attr store

The L<store|Statocles::Store> to read for documents.

=cut

has store => (
    is => 'ro',
    isa => InstanceOf['Statocles::Store'],
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
    isa => InstanceOf['Statocles::Theme'],
    required => 1,
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

sub command {
    my ( $self, $name, @argv ) = @_;
    if ( $argv[0] eq 'help' ) {
        print <<ENDHELP;
$name help -- This help file
$name post [--date YYYY-MM-DD] <title> -- Create a new blog post with the given title
ENDHELP
    }
    elsif ( $argv[0] eq 'post' ) {
        my %opt;
        GetOptionsFromArray( \@argv, \%opt,
            'date:s',
        );

        my $title = join " ", @argv[1..$#argv];
        if ( !$ENV{EDITOR} && !$title ) {
            print STDERR <<"ENDHELP";
Title is required when \$EDITOR is not set.

Usage: $name post <title>
ENDHELP
            return 1;
        }

        my $slug = lc $title;
        $slug =~ s/\s+/-/g;

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

        my $path = Path::Tiny->new( @date_parts, "$slug.yml" );
        my %doc = (
            %$default_post,
            title => $title,
            last_modified => Time::Piece->new,
        );
        my $full_path = $self->store->write_document( $path => \%doc );
        print "New post at: $full_path\n";
        if ( $ENV{EDITOR} ) {
            system $ENV{EDITOR}, $full_path;
        }
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

        push @pages, Statocles::Page::Document->new(
            app => $self,
            layout => $self->theme->template( site => 'layout.html' ),
            template => $self->theme->template( blog => 'post.html' ),
            document => $doc,
            path => $path,
            published => Time::Piece->strptime( $date, '%Y-%m-%d' ),
        );
    }
    return @pages;
}
memoize( 'post_pages' );

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
    my ( $self ) = @_;

    my @pages = Statocles::Page::List->paginate(
        after => $self->page_size,
        path => join( "/", $self->url_root, 'page-%i.html' ),
        index => join( "/", $self->url_root, 'index.html' ),
        # Sorting by path just happens to also sort by date
        pages => [ sort { $b->path cmp $a->path } $self->post_pages ],
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
memoize( 'index' );

=method tag_pages()

Get L<pages|Statocles::Page> for the tags in the blog post documents.

=cut

sub tag_pages {
    my ( $self ) = @_;

    my %tagged_docs = $self->_tag_docs;

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
memoize( 'tag_pages' );

=method pages()

Get all the L<pages|Statocles::Page> for this application.

=cut

sub pages {
    my ( $self ) = @_;
    return map { $self->$_ } qw( post_pages index tag_pages );
}

=method tags()

Get a set of hashrefs suitable for creating a list of tag links. The hashrefs
contain the following keys:

    title => 'The tag text'
    href => 'The URL to the tag page'

=cut

sub tags {
    my ( $self ) = @_;
    my %tagged_docs = $self->_tag_docs;
    return map {; { title => $_, href => $self->_tag_url( $_ ), } }
        sort keys %tagged_docs
}

sub _tag_docs {
    my ( $self ) = @_;
    my %tagged_docs;
    for my $page ( $self->post_pages ) {
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


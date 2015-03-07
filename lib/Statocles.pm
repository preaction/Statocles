package Statocles;
# ABSTRACT: A static site generator

# The currently-running site.
# I hate this, but I know of no better way to ensure that we always have access
# to a Mojo::Log object, while still being relatively useful, without having to
# wire up every single object with a log object.
our $SITE;

BEGIN {
    package # Hide from PAUSE
        site;
    sub log { return $SITE->log }
}

use Statocles::Base;


1;
__END__

=head1 SYNOPSIS

    # Create a new site
    mkdir www.example.com
    cd www.example.com
    statocles create

    # Create a new blog post
    export EDITOR=vim
    statocles blog post

    # Build the site
    statocles build

    # Test the site in a local web browser
    statocles daemon

    # Deploy the site
    statocles deploy

=head1 DESCRIPTION

Statocles is an application for building static web pages from a set of plain
YAML and Markdown files. It is designed to make it as simple as possible to
develop rich web content using basic text-based tools.

=head2 FEATURES

=over

=item *

A simple format based on
L<Markdown|http://daringfireball.net/projects/markdown/> for editing site
content.

=item *

A command-line application for building, deploying, and editing the site.

=item *

A simple daemon to display a test site before it goes live.

=item *

A L<blogging application|Statocles::App::Blog#FEATURES> with

=over

=item *

RSS and Atom syndication feeds.

=item *

Tags to organize blog posts. Tags have their own custom feeds.

=item *

Crosspost links to direct users to a syndicated blog.

=item *

Post-dated blog posts to appear automatically when the date is passed.

=back

=item *

Customizable L<themes|Statocles::Theme> using L<the Mojolicious template
language|Mojo::Template#SYNTAX>.

=item *

A clean default theme using L<the Skeleton CSS library|http://getskeleton.com>.

=item *

SEO-friendly features such as L<sitemaps (sitemap.xml)|http://www.sitemaps.org>.

=back

=head1 GETTING STARTED

To get started with Statocles, L<consult the Statocles::Help guides|Statocles::Help>.

=head1 SEE ALSO

For news and documentation, L<visit the Statocles website at
http://preaction.github.io/Statocles|http://preaction.github.io/Statocles>.

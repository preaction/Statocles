package Statocles;
# ABSTRACT: A static site generator

# This module exists for both documentation and to help File::Share
# find the right share dir

1;
__END__

=head1 GUIDES

=head2 GETTING STARTED

To get started with your own Statocle site, see
L<the Statocles setup help in Statocles::Help::Setup|Statocles::Help::Setup>.

=head1 DESCRIPTION

Statocles is an application for building static web pages from a set of plain
YAML and Markdown files. It is designed to make it as simple as possible to
develop rich web content using basic text-based tools.

=head1 OVERVIEW

=head2 DOCUMENTS

A L<document|Statocles::Document> is the main content of the site. The user does
all the work with documents: adding, editing, and removing documents.

The default store reads documents in a combined YAML and Markdown format,
easily editable with any text editor. A sample document looks like:

    ---
    title: This is a title
    author: preaction
    ---
    # This is the markdown content

    This is a paragraph

This is the same format that L<Jekyll|http://jekyllrb.com> uses. The document
format is described in the L<Statocles::Store> documentation under
L<Frontmatter Document Format|Statocles::Store/"Frontmatter Document Format">.

=head2 PAGES

A L<Statocles::Page> is rendered HTML ready to be sent to a user. Statocles
generates pages from the documents that the user provides. One document may
generate multiple pages, and pages may have multiple formats like HTML or RSS.

=over 4

=item L<Statocles::Page::Document>

This page renders a single document. This is used for the main page of a blog
post, for example.

=item L<Statocles::Page::List>

This page renders a list of other pages (not documents). This is used for index
pages.

=back

=head1 APPLICATIONS

An application is the module that will take the documents the user provides and
turn them into the pages that can be written out to the filesystem.

=over 4

=item L<Statocles::App::Blog>

A simple blogging application.

=back

=head1 SITES

A L<Statocles::Site> manages a bunch of applications, writing and deploying the
resulting pages.

Deploying the site may involve a simple file copy, but it could also involve a
Git repository, an FTP site, or a database.

=over 4

=item L<Statocles::Site::Git>

A simple Git repository site.

=back

=head1 STORES

A L<Statocles::Store> reads and writes documents and pages. The default store
reads documents in YAML and writes pages to a file, but stores could read
documents as JSON, or from a Mongo database, and write pages to a database, or
whereever you want!

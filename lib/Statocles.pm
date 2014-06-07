package Statocles;
# ABSTRACT: A static site generator

# This module exists for both documentation and to help File::Share
# find the right share dir

1;
__END__

=head1 GETTING STARTED

To get started with your own Statocle site, see
L<the setup help|Statocles::Help::Setup>.

=head1 DESCRIPTION

This document is an overview of the Statocles application.

Statocles is a tool for building static HTML pages from documents.

=head2 DOCUMENTS

A L<document|Statocles::Document> is a data structure. The default store reads documents in a combined
YAML and Markdown format.

Documents are formatted with a YAML document on top, and Markdown content
on the bottom, like so:

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

A L<Statocles::Page> is rendered HTML ready to be sent to a user.

=over 4

=item L<Statocles::Page::Document>

This page renders a single document.

=item L<Statocles::Page::List>

This page renders a list of other pages (not documents).

=back

=head1 APPLICATIONS

An application takes a bunch of documents and turns them into HTML pages.

=over 4

=item L<Statocles::App::Blog>

A simple blogging application.

=back

=head1 SITES

A L<Statocles::Site> manages a bunch of applications, writing and deploying the resulting
pages.

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

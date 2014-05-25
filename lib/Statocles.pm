package Statocles;
# ABSTRACT: A static site generator

# This module exists for both documentation and to help File::Share
# find the right share dir

1;
__END__

=head1 DESCRIPTION

Statocles is a tool for building static HTML pages from documents.

=head2 DOCUMENTS

A document is a data structure. The default store reads documents in YAML.

=head2 PAGES

A page is rendered HTML ready to be sent to a user.

=head1 APPLICATIONS

An application takes a bunch of documents and turns them into HTML pages.

=over 4

=item L<Statocles::App::Blog>

A simple blogging application.

=back

=head1 SITES

A site manages a bunch of applications, writing and deploying the resulting
pages.

Deploying the site may involve a simple file copy, but it could also involve a
Git repository, an FTP site, or a database.

=head1 STORES

A store reads and writes documents and pages. The default store reads documents
in YAML and writes pages to a file, but stores could read documents as JSON, or
from a Mongo database, and write pages to a database, or whereever you want!

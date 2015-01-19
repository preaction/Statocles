package Statocles::Store;
# ABSTRACT: Base role for repositories of documents and files

use Statocles::Base 'Role';

=attr base_url

The base URL for this Store when deploying. Site URLs will be automatically
rewritten to be based on this URL.

This allows you to have different versions of the site deployed to different
URLs.

=cut

has base_url => (
    is => 'ro',
    isa => Str,
);

1;
__END__

=head1 DESCRIPTION

A Statocles::Store reads and writes L<documents|Statocles::Document> and
files (mostly L<pages|Statocles::Page>).

This class handles the parsing and inflating of
L<"document objects"|Statocles::Document>.

=head1 SEE ALSO

=over 4

=item L<Statocles::Store::File> - A store for plain files

=back


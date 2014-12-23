package Statocles::Store;
# ABSTRACT: Base role for repositories of documents and files

use Statocles::Base 'Role';

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


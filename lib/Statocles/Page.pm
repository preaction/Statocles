package Statocles::Page;
# ABSTRACT: Render documents into HTML

use Statocles::Role;
use Text::Markdown;
use Text::Template;

requires 'render';

has path => (
    is => 'ro',
    isa => Str,
);

has markdown => (
    is => 'ro',
    isa => InstanceOf['Text::Markdown'],
    default => sub { Text::Markdown->new },
);

my @template_attrs = (
    is => 'ro',
    isa => InstanceOf['Text::Template'],
    coerce => sub {
        die "Template is undef" unless defined $_[0];
        return !ref $_[0] 
            ? Text::Template->new( TYPE => 'STRING', SOURCE => $_[0] )
            : $_[0]
            ;
    },
);

has template => @template_attrs;
has layout => (
    @template_attrs,
    default => sub {
        Text::Template->new( type => 'STRING', source => '{$content}' ),
    },
);

1;
__END__

=head1 DESCRIPTION

A Statocles::Page takes one or more documents and renders them into one or more
HTML pages.

=head1 SEE ALSO

=over

=item L<Statocles::Page::Document>

A page that renders a single document.

=item L<Statocles::Page::List>

A page that renders a list of other pages.

=back


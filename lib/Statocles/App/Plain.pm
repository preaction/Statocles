package Statocles::App::Plain;
# ABSTRACT: Plain documents made into pages with no extras

use Statocles::Base 'Class';
use Statocles::Page::Document;
use Statocles::Util qw( run_editor );
with 'Statocles::App';

=attr store

The L<store|Statocles::Store> containing this app's documents. Required.

=cut

has store => (
    is => 'ro',
    isa => Store,
    required => 1,
    coerce => Store->coercion,
);

=method pages

    my @pages = $app->pages;

Get the L<page objects|Statocles::Page> for this app.

=cut

sub pages {
    my ( $self ) = @_;
    my @pages;

    for my $doc ( @{ $self->store->documents } ) {
        my $url = $doc->path;
        $url =~ s/[.]markdown$/.html/;

        my $page = Statocles::Page::Document->new(
            app => $self,
            path => $url,
            document => $doc,
            layout => $self->site->theme->template( site => 'layout.html' ),
        );

        if ( $url =~ m{^/?index[.]html$} ) {
            unshift @pages, $page;
        }
        else {
            push @pages, $page;
        }
    }

    return @pages;
}

=method command

    my $exitval = $app->command( $app_name, @args );

Run a command on this app. Commands allow creating, editing, listing, and
viewing pages.

=cut

my $USAGE_INFO = <<'ENDHELP';
Usage:
    $name help -- This help file
    $name edit <path> -- Edit a page, creating it if necessary
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
        return 0;
    }

    if ( $argv[0] eq 'edit' ) {
        $argv[1] =~ s{^/}{};
        my $path = Path::Tiny->new(
            $argv[1] =~ /[.](?:markdown|md)$/ ? $argv[1] : "$argv[1]/index.markdown",
        );

        my %doc;
        # Read post content on STDIN
        if ( !-t *STDIN ) {
            my $content = do { local $/; <STDIN> };
            %doc = (
                %doc,
                $self->store->parse_frontmatter( "<STDIN>", $content ),
            );

            # Re-open STDIN as the TTY so that the editor (vim) can use it
            # XXX Is this also a problem on Windows?
            if ( -e '/dev/tty' ) {
                close STDIN;
                open STDIN, '/dev/tty';
            }
        }

        if ( !$self->store->has_file( $path ) || keys %doc ) {
            $doc{title} ||= '';
            $doc{content} ||= "Markdown content goes here.\n";
            $self->store->write_document( $path => \%doc );
        }
        my $full_path = $self->store->path->child( $path );

        if ( !run_editor( $full_path ) ) {
            say "New page at: $full_path";
        }

    }
    else {
        say STDERR qq{ERROR: Unknown command "$argv[0]"};
        say STDERR eval "qq{$USAGE_INFO}";
        return 1;
    }

    return 0;
}

1;
__END__

=head1 SYNOPSIS

    my $app = Statocles::App::Plain->new(
        url_root => '/',
        store => 'share/root',
    );
    my @pages = $app->pages;

=head1 DESCRIPTION

This application builds simple pages based on L<documents|Statocles::Document>. Use this
to have basic informational pages like "About Us" and "Contact Us".


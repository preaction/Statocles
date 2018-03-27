package Statocles::App::Basic;
our $VERSION = '0.091';
# ABSTRACT: Build Markdown and collateral files

use Statocles::Base 'Class';
use Statocles::Document;
use Statocles::Util qw( run_editor read_stdin );
with 'Statocles::App::Role::Store';

=attr store

The L<store path|Statocles::Store> containing this app's documents and files.
Required.

=cut

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

        # Read post content on STDIN
        if ( my $content = read_stdin() ) {
            my $doc = Statocles::Document->parse_content(
                path => $path.'',
                store => $self->store,
                content => $content,
            );
            $self->store->write_file( $path => $doc );
        }
        elsif ( !$self->store->has_file( $path ) ) {
            my $doc = Statocles::Document->new(
                content => "Markdown content goes here.\n",
            );
            $self->store->write_file( $path => $doc );
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

    my $app = Statocles::App::Basic->new(
        url_root => '/',
        store => 'share/root',
    );
    my @pages = $app->pages;

=head1 DESCRIPTION

This application builds basic pages based on L<Markdown documents|Statocles::Document> and
other files. Use this to have basic informational pages like "About Us" and "Contact Us".


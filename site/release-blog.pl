package release_blog;

use strict;
use warnings;
use v5.10;
use CPAN::Changes;
use Getopt::Long qw( GetOptionsFromArray );
use Pod::Usage::Return;

my $GITHUB_ROOT = 'https://github.com/preaction/Statocles';
my $DIST = "Statocles";
my $CHANGES_FILE = 'CHANGES';
my $NEXT_TOKEN = qr/\{\{\s*\$NEXT\s*\}\}/;

sub main {
    my ( $class, @args ) = @_;

    my %opt;
    GetOptionsFromArray( \@args, \%opt,
        'help|h',
    );
    return pod2usage(0) if $opt{help};

    my $changes = CPAN::Changes->load(
        $CHANGES_FILE,
        next_token => $NEXT_TOKEN,
    );

    my $release;
    if ( my $version = shift @args ) {
        $release = $changes->release( $version ) || die "Could not find version $version in $CHANGES_FILE\n";
    }
    else {
        my @releases = $changes->releases;
        if ( $releases[-1]->version !~ $NEXT_TOKEN ) {
            $release = $releases[-1];
        }
        else {
            $release = $releases[-2];
        }
    }

    my $version = $release->version;

    say "---";
    say "title: Release v$version";
    say "tags: release";
    say "---";
    say "";
    say "In this release:";
    say "";
    say "[More information about $DIST v$version on MetaCPAN](http://metacpan.org/release/PREACTION/$DIST-$version)";

    for my $group ( $release->groups ) {
        say "## $group";
        say "";
        for my $change ( @{ $release->changes( $group ) } ) {
            $change =~ s{\[Github \#(\d+)\]}{[\[Github #$1\]]($GITHUB_ROOT/issues/$1)}g;
            $change =~ s{\@(\w+)}{[\@$1](http://github.com/$1)}g;
            say "* " . $change;
        }
        say "";
    }

    return 0;
}

exit release_blog->main( @ARGV ) unless caller;

1;
__END__

=head1 NAME

release-blog.pl - Prepare a release blog entry for this project

=head1 SYNOPSIS

    release-blog.pl [<version>]
    release-blog.pl --help|-h

=head1 DESCRIPTION

This script prepares the list of changes from the CHANGES file and adds
links to any tickets referenced in the commit.

=head1 ARGUMENTS

=head2 version

Optional. The version to use. Defaults to the latest release.

=head1 OPTIONS

=head2 --help|-h

See the help for this command.


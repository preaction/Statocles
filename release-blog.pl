package release_blog;

use Statocles::Base;
use Git::Repository;
use Getopt::Long qw( GetOptionsFromArray );
use Pod::Usage::Return;
use List::MoreUtils qw( firstidx );

my $GITHUB_ROOT = 'https://github.com/preaction/Statocles';

sub main {
    my ( $class, @args ) = @_;

    my %opt;
    GetOptionsFromArray( \@args, \%opt,
        'help|h',
    );
    return pod2usage(0) if $opt{help};

    my $version = shift @args;

    my $git = Git::Repository->new( work_tree => '.' );
    my @tags = $git->run( 'tag' );

    my $tag_idx = $version ? firstidx { $_ eq $version } @tags : $#tags;
    if ( $tag_idx < 0 ) {
        say "ERROR: Could not find version tag '$version'.";
        return 1;
    }

    my $full_log = $git->run( log => '--pretty=%H %s%n%n%b---', "$tags[$tag_idx-1]..$tags[$tag_idx]" );

    for my $log ( split /\n---\n?/, $full_log ) {
        my ( $first, undef, $body ) = split /\n/, $log, 3;
        $body //= '';

        my ( $sha, $title ) = split ' ', $first, 2;
        my $commit_url = join '/', $GITHUB_ROOT, 'commit', $sha;
        my $item = sprintf '[%s](%s)', $title, $commit_url;

        my @tickets;
        for my $ticket_num ( $body =~ /\#(\d+)/g ) {
            my $ticket_url = join '/', $GITHUB_ROOT, 'issues', $ticket_num;
            push @tickets, sprintf '[#%d](%s)', $ticket_num, $ticket_url;
        }
        if ( @tickets ) {
            $item .= ' (' . join( ', ', @tickets ) . ')';
        }

        say "* $item";
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

This script prepares the list of commits with links to Github for the commits and
any tickets referenced in the commit.

=head1 ARGUMENTS

=head2 version

Optional. The tag to collect. Commits between this tag and the previous tag
will be collected. Defaults to the latest release tag.

=head1 OPTIONS

=head2 --help|-h

See the help for this command.


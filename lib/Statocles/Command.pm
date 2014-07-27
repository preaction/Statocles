package Statocles::Command;
# ABSTRACT: The statocles command-line interface

use Statocles::Class;
use Getopt::Long qw( GetOptionsFromArray );
use Pod::Usage::Return qw( pod2usage );
use File::Share qw( dist_dir );
use File::Copy::Recursive qw( dircopy );
use Beam::Wire;

=attr site

The L<site|Statocles::Site> we're working with.

=cut

has site => (
    is => 'ro',
    isa => InstanceOf['Statocles::Site'],
);

=method main( @argv )

Run the command given in @argv. See L<statocles> for a list of commands and
options.

=cut

sub main {
    my ( $class, @argv ) = @_;

    my %opt = (
        config => 'site.yml',
        site => 'site',
        verbose => 0,
    );
    GetOptionsFromArray( \@argv, \%opt,
        'config:s',
        'site:s',
        'help|h',
        'version',
        'verbose|v+',
    );
    return pod2usage(0) if $opt{help};

    if ( $opt{version} ) {
        print "Statocles version $Statocles::Command::VERSION (Perl $^V)\n";
        return 0;
    }

    local $Statocles::VERBOSE = $opt{verbose};

    my $wire = Beam::Wire->new( file => $opt{config} );

    my $cmd = $class->new(
        site => $wire->get( $opt{site} ),
    );

    my $method = $argv[0];
    if ( grep { $_ eq $method } qw( build deploy ) ) {
        $cmd->site->$method;
        return 0;
    }
    elsif ( $method eq 'apps' ) {
        my $apps = $cmd->site->apps;
        for my $app_name ( keys %{ $apps } ) {
            my $app = $apps->{$app_name};
            my $root = $app->url_root;
            my $class = ref $app;
            print "$app_name ($root -- $class)\n";
        }
        return 0;
    }
    elsif ( $method eq 'daemon' ) {
        require Mojo::Server::Daemon;
        my $daemon = Mojo::Server::Daemon->new(
            silent => 1,
            app => Statocles::Command::_MOJOAPP->new(
                site => $cmd->site,
            ),
        );
        print "Listening on " . $daemon->listen->[0] . "\n";
        $daemon->run;
    }
    elsif ( $method eq 'bundle' ) {
        my $what = $argv[1];
        if ( $what eq 'theme' ) {
            my $theme_name = $argv[2];
            my $theme_root = Path::Tiny->new( dist_dir( 'Statocles' ), 'theme', $theme_name );
            my $site_root = Path::Tiny->new( $opt{config} )->parent;
            my $theme_dest = $site_root->child(qw( share theme ), $theme_name );
            my $iter = $theme_root->iterator({ recurse => 1 });
            while ( my $path = $iter->() ) {
                next unless $path->is_file;
                my $relative = $path->relative( $theme_root );
                my $dest = $theme_dest->child( $relative );
                # Don't overwrite site-customized hooks
                next if ( $path->stat->size == 0 && $dest->exists );
                $dest->touchpath;
                $path->copy( $dest );
            }
            say qq{Theme "$theme_name" written to "share/theme/$theme_name"};
            say qq{Make sure to update "$opt{config}"};
        }
    }
    else {
        my $app_name = $method;
        return $cmd->site->apps->{ $app_name }->command( @argv );
    }

    return 0;
}

package Statocles::Command::_MOJOAPP;

use Mojo::Base 'Mojolicious';
has 'site';

sub startup {
    my ( $self ) = @_;
    $self->routes->get( '/', sub { $_[0]->redirect_to( '/index.html' ) } );
    unshift @{ $self->static->paths },
        $self->site->build_store->path,
        # Add the deploy store for non-Statocles content
        # This won't work in certain situations, like a Git repo on another branch, but
        # this is convenience until we can track image directories and other non-generated
        # content.
        $self->site->deploy_store->path;
}

1;
__END__

=head1 SYNOPSIS

    use Statocles::Command;
    exit Statocles::Command->main( @ARGV );

=head1 DESCRIPTION

This module implements the Statocles command-line interface.

=head1 SEE ALSO

=over 4

=item L<statocles>

The documentation for the command-line application.

=back

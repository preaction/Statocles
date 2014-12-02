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

    my $method = $argv[0];
    return pod2usage("ERROR: Missing command") unless $method;

    local $Statocles::VERBOSE = $opt{verbose};

    my $wire = Beam::Wire->new( file => $opt{config} );

    my $cmd = $class->new(
        site => $wire->get( $opt{site} ),
    );

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
        our $daemon = Mojo::Server::Daemon->new(
            silent => 1,
            app => Statocles::Command::_MOJOAPP->new(
                site => $cmd->site,
            ),
        );

        # Using start() instead of run() so we can stop() inside the tests
        $daemon->start;

        # Find the port we're listening on
        my $id = $daemon->acceptors->[0];
        my $handle = $daemon->ioloop->acceptor( $id )->handle;
        print "Listening on " . sprintf( 'http://%s:%d', $handle->sockhost || '127.0.0.1', $handle->sockport ) . "\n";

        # Give control to the IOLoop
        Mojo::IOLoop->start;
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

{
    package # Do not index this
        Statocles::Command::_MOJOAPP;

    # Currently, as of Mojolicious 5.12, loading the Mojolicious module here
    # will load the Mojolicious::Commands module, which calls GetOptions, which
    # will remove -h, --help, -m, and -s from @ARGV. We fix this by copying
    # @ARGV in bin/statocles before we call Statocles::Command.
    #
    # We could fix this in the future by moving this out into its own module,
    # that is only loaded after we are done passing @ARGV into main(), above.
    use Mojo::Base 'Mojolicious';
    has 'site';

    sub startup {
        my ( $self ) = @_;
        my $base;
        if ( $self->site->base_url ) {
            $base = Mojo::URL->new( $self->site->base_url )->path->to_string;
            $base =~ s{/$}{};
        }

        my $index = "/index.html";
        if ( $base ) {
            $index = $base . $index;
        }

        unshift @{ $self->static->paths },
            $self->site->build_store->path,
            # Add the deploy store for non-Statocles content
            # This won't work in certain situations, like a Git repo on another branch, but
            # this is convenience until we can track image directories and other non-generated
            # content.
            $self->site->deploy_store->path;

        my $serve_static = sub {
            my ( $c ) = @_;
            my $path = Mojo::Path->new( $c->stash->{path} );

            # Taint check the path, just in case someone uses this "dev" tool to
            # serve real content
            return $c->render( status => 400, text => "You didn't say the magic word" )
                if $path->canonicalize->parts->[0] eq '..';

            my $asset = $self->static->file( $path );
            if ( !$asset ) {
                # Check for index.html
                my $path = Mojo::Path->new( $c->stash->{path} . "/index.html" );
                $asset = $self->static->file( $path );
            }

            if ( !$asset ) {
                return $c->render( status => 404, text => 'Not found' );
            }

            return $c->reply->asset( $asset );
        };

        if ( $base ) {
            $self->routes->get( '/', sub {
                my ( $c ) = @_;
                $c->redirect_to( $base );
            } );
            $self->routes->get( $base . '/*path' )->to( path => 'index.html', cb => $serve_static );
        }
        else {
            $self->routes->get( '/*path' )->to( path => 'index.html', cb => $serve_static );
        }

    }

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

package Statocles::Command::daemon;
our $VERSION = '0.097';
# ABSTRACT: Run a daemon to navigate the site

use Statocles::Base 'Command';
use Statocles::Store;

sub run {
    my ( $self, @argv ) = @_;
    # Build the site first no matter what.  We may end up watching for
    # future changes, but assume they meant to build first
    my %build_opt;
    GetOptionsFromArray( \@argv, \%build_opt,
        'port|p=i',
        'date|d=s',
    );

    require Mojo::Server::Daemon;
    my $app = Statocles::Command::daemon::_MOJOAPP->new(
        site => $self->site,
        options => \%build_opt,
    );
    our $daemon = Mojo::Server::Daemon->new(
        silent => 1,
        app => $app,
    );

    if ( $build_opt{port} ) {
        $daemon->listen([ "http://*:$build_opt{port}" ]);
    }

    # Using start() instead of run() so we can stop() inside the tests
    $daemon->start;

    # Find the port we're listening on
    my $id = $daemon->acceptors->[0];
    my $handle = $daemon->ioloop->acceptor( $id )->handle;
    say "Listening on " . sprintf( 'http://%s:%d', $handle->sockhost || '127.0.0.1', $handle->sockport );

    # Give control to the IOLoop
    Mojo::IOLoop->start;

    return 0;
}

{
    package # Do not index this
        Statocles::Command::daemon::_MOJOAPP;

    # Currently, as of Mojolicious 5.12, loading the Mojolicious module here
    # will load the Mojolicious::Commands module, which calls GetOptions, which
    # will remove -h, --help, -m, and -s from @ARGV. We fix this by copying
    # @ARGV in bin/statocles before we call Statocles::Command.
    #
    # We could fix this in the future by moving this out into its own module,
    # that is only loaded after we are done passing @ARGV into main(), above.
    use Mojo::Base 'Mojolicious';
    use Scalar::Util qw( weaken );
    use File::Share qw( dist_dir );
    has 'site';
    has options => sub { {} };
    has cleanup => sub { Mojo::Collection->new };

    sub DESTROY {
        my ( $self, $in_global_destruction ) = @_;
        return unless $self->cleanup;
        $self->cleanup->each( sub { $_->() } );
    }

    sub startup {
        my ( $self ) = @_;
        $self->log( $self->site->log );

        # First build the site
        my $path = Path::Tiny->new( '.statocles/build' );
        $path->mkpath;
        my $store = Statocles::Store->new( path => $path );
        $store->write_file( $_->path, $_->render ) for $self->site->pages( %{ $self->options } );

        my $base;
        if ( $self->site->base_url ) {
            $base = Mojo::URL->new( $self->site->base_url )->path->to_string;
            $base =~ s{/$}{};
        }

        my $index = "/index.html";
        if ( $base ) {
            $index = $base . $index;
        }

        # Add the build dir to the list of static paths for mojolicious to
        # search
        unshift @{ $self->static->paths }, $store->path;

        # Watch for filesystem events and rebuild the site Right now this only
        # works on OSX. We should spin this off into Mojo::IOLoop::FSEvents and
        # make it work cross-platform, including a pure-Perl fallback
        my $can_watch = eval { require Mac::FSEvents; 1 };
        if ( !$can_watch && $^O =~ /darwin/ ) {
            say "To watch for filesystem changes and automatically rebuild the site, ",
                "install the Mac::FSEvents module from CPAN";
        }

        if ( $can_watch ) {

            # Collect the paths to watch
            my %watches = ();
            for my $app ( values %{ $self->site->apps } ) {
                if ( $app->can( 'store' ) ) {
                    push @{ $watches{ $app->store->path } }, $app->store;
                }
            }

            # Watch the theme, but not built-in themes
            my $theme_path = $self->site->theme->store->path;
            if ( !Path::Tiny->new( dist_dir( 'Statocles' ) )->subsumes( $theme_path ) ) {
                push @{ $watches{ $theme_path } }, $self->site->theme;
            }

            require Mojo::IOLoop::Stream;
            my $ioloop = Mojo::IOLoop->singleton;
            my $build_dir = $store->path->realpath;

            weaken $self;

            for my $path ( keys %watches ) {
                $self->log->info( "Watching for changes in '$path'" );

                my $fs = Mac::FSEvents->new( {
                    path => "$path",
                    latency => 1.0,
                } );
                my $handle = $fs->watch;

                push @{ $self->cleanup }, sub {
                    return if !$fs || !$handle;
                    $fs->stop;
                    Mojo::IOLoop->remove( $handle );
                };

                $ioloop->reactor->io( $handle, sub {
                    my ( $reactor, $writable ) = @_;

                    my $rebuild;
                    REBUILD:
                    for my $event ( $fs->read_events ) {
                        if ( $event->path =~ /^\Q$build_dir/ ) {
                            next;
                        }

                        $self->log->info( "Path '" . $event->path . "' changed... Rebuilding" );
                        $_->can('clear') && $_->clear for @{ $watches{ $path } };
                        $rebuild = 1;
                    }

                    if ( $rebuild ) {
                        $self->site->clear_pages;
                        $store->write_file( $_->path, $_->render ) for $self->site->pages( %{ $self->options } );
                    }
                } );
                $ioloop->reactor->watch( $handle, 1, 0 );
            }

            $self->log->info( "Ignoring changes in '$build_dir'" );
        }

        my $serve_static = sub {
            my ( $c ) = @_;
            my $path = Mojo::Path->new( $c->stash->{path} );

            # Taint check the path, just in case someone uses this "dev" tool to
            # serve real content
            return $c->render( status => 400, text => "You didn't say the magic word" )
                if $path->canonicalize->parts->[0] eq '..';

            my $asset = $c->app->static->file( $path );
            if ( !$asset ) {
                if ( $path =~ m{/$} ) {
                    # Check for index.html
                    $path = Mojo::Path->new( $c->stash->{path} . "/index.html" );
                    $asset = $c->app->static->file( $path );
                }
                elsif ( $store->path->child( $path )->is_dir ) {
                    return $c->redirect_to( "/$path/" );
                }
            }

            if ( !$asset ) {
                return $c->render( status => 404, text => 'Not found' );
            }

            # The static helper will choose the right content type and charset
            return $c->reply->static( $path );
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

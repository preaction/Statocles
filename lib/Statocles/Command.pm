package Statocles::Command;
# ABSTRACT: The statocles command-line interface

use Statocles::Base 'Class';
use Scalar::Util qw( blessed );
use Getopt::Long qw( GetOptionsFromArray :config pass_through );
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
        say "Statocles version $Statocles::Command::VERSION (Perl $^V)";
        return 0;
    }

    my $method = $argv[0];
    return pod2usage("ERROR: Missing command") unless $method;

    # Create site does not require a config file
    if ( $method eq 'create' ) {
        return $class->new->create_site( \@argv, \%opt );
    }

    if ( !-e $opt{config} ) {
        warn sprintf qq{ERROR: Could not find config file "\%s"\n}, $opt{config};
        return 1;
    }

    my $wire = Beam::Wire->new( file => $opt{config} );
    my $site = eval { $wire->get( $opt{site} ) };

    if ( $@ ) {
        if ( blessed $@ && $@->isa( 'Beam::Wire::Exception::NotFound' ) ) {
            warn sprintf qq{ERROR: Could not find site named "%s" in config file "%s"\n},
                $opt{site}, $opt{config};
            return 1;
        }
        die $@;
    }

    my $cmd = $class->new( site => $site );

    if ( $opt{verbose} ) {
        $cmd->site->log->handle( \*STDOUT );
        $cmd->site->log->level( 'debug' );
    }

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
            say "$app_name ($root -- $class)";
        }
        return 0;
    }
    elsif ( $method eq 'daemon' ) {
        # Build the site first no matter what.  We may end up watching for
        # future changes, but assume they meant to build first
        $cmd->site->build;

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
        say "Listening on " . sprintf( 'http://%s:%d', $handle->sockhost || '127.0.0.1', $handle->sockport );

        # Give control to the IOLoop
        Mojo::IOLoop->start;
    }
    elsif ( $method eq 'bundle' ) {
        my $what = $argv[1];
        if ( $what eq 'theme' ) {
            my $theme_name = $argv[2];
            if ( !$theme_name ) {
                say STDERR "ERROR: No theme name!";
                say STDERR "\nUsage:\n\tstatocles bundle theme <name> <destination>";
                return 1;
            }

            if ( !$argv[3] ) {
                say STDERR "ERROR: Must give a destination directory!";
                say STDERR "\nUsage:\n\tstatocles bundle theme <name> <destination>";
                return 1;
            }

            $cmd->bundle_theme( $theme_name, $argv[3] );
            say qq{Theme "$theme_name" written to "$argv[3]"};
            say qq(Make sure to update "$opt{config}");
        }
    }
    else {
        my $app_name = $method;
        return $cmd->site->apps->{ $app_name }->command( @argv );
    }

    return 0;
}

sub create_site {
    my ( $self, $argv, $opt ) = @_;

    my %answer;

    my $create_dir = Path::Tiny->new( dist_dir( 'Statocles' ) )->child( 'create' );
    my $question = YAML::Load( $create_dir->child( 'script.yml' )->slurp_utf8 );
    my %prompt = (
        flavor => 'Which flavor of site would you like? ([1], 2, 0)',
        bundle_theme => 'Do you want to bundle the theme? ([Y]/n)',
        deploy_class => 'How would you like to deploy? ([1], 2, 0)',
        git_branch => 'What branch? [master]',
        deploy_path => 'Where to deploy the site? (default: current directory)',
    );

    print "\n", $question->{flavor};
    print "\n", "\n", $prompt{flavor}, " ";
    chomp( $answer{flavor} = <STDIN> );
    until ( $answer{flavor} =~ /^[120]*$/ ) {
        print $prompt{flavor}, " ";
        chomp( $answer{flavor} = <STDIN> );
    }
    $answer{flavor} = 1 if $answer{flavor} eq '';

    print "\n", "\n", $question->{bundle_theme};
    print "\n", "\n", $prompt{bundle_theme}, " ";
    chomp( $answer{bundle_theme} = <STDIN> );
    until ( $answer{bundle_theme} =~ /^[yn]*$/i ) {
        print $prompt{bundle_theme}, " ";
        chomp( $answer{bundle_theme} = <STDIN> );
    }
    $answer{bundle_theme} = "y" if $answer{bundle_theme} eq '';

    print "\n", "\n", $question->{deploy_class};
    print "\n", "\n", $prompt{deploy_class}, " ";
    chomp( $answer{deploy_class} = <STDIN> );
    until ( $answer{deploy_class} =~ /^[120]*$/i ) {
        print $prompt{deploy_class}, " ";
        chomp( $answer{deploy_class} = <STDIN> );
    }
    $answer{deploy_class} = 1 if $answer{deploy_class} eq '';

    if ( $answer{deploy_class} == 1 ) {
        # Git deploy questions
        print "\n", "\n", $question->{git_branch};
        print "\n", "\n", $prompt{git_branch}, " ";
        chomp( $answer{git_branch} = <STDIN> );
        $answer{git_branch} ||= "master";
    }
    elsif ( $answer{deploy_class} == 2 ) {
        # File deploy questions
        print "\n", "\n", $question->{deploy_path};
        print "\n", "\n", $prompt{deploy_path}, " ";
        chomp( $answer{deploy_path} = <STDIN> );
        $answer{deploy_path} ||= '.';
    }

    ### Build the site
    my ( $site ) = YAML::Load( $create_dir->child( 'site.yml' )->slurp_utf8 );

    if ( $answer{flavor} == 1 ) {
        $site->{site}{args}{index} = "blog";
        $site->{site}{args}{nav}{main}[0]{href} = "/";
    }
    elsif ( $answer{flavor} == 2 ) {
        $site->{site}{args}{index} = "page";
        $site->{site}{args}{nav}{main}[0]{href} = "/blog";
    }

    if ( lc $answer{bundle_theme} eq 'y' ) {
        $self->bundle_theme( 'default', 'theme' );
        $site->{theme}{args}{store} = 'theme';
    }

    if ( $answer{deploy_class} == 1 ) {
        $site->{deploy}{class} = 'Statocles::Deploy::Git';
        $site->{deploy}{args}{branch} = $answer{git_branch};
    }
    elsif ( $answer{deploy_class} == 2 ) {
        $site->{deploy}{class} = 'Statocles::Deploy::File';
        $site->{deploy}{args}{path} = $answer{deploy_path};
    }
    else {
        # We need a deploy in order to create a Site object
        $site->{deploy}{class} = 'Statocles::Deploy::File';
        $site->{deploy}{args}{path} = '.';
    }

    Path::Tiny->new( '.' )->child( 'site.yml' )->spew_utf8( YAML::Dump( $site ) );

    ### DONE!
    print "\n", "\n", $question->{finish}, "\n", "\n";
    return 0;
}

sub bundle_theme {
    my ( $self, $name, $dir ) = @_;
    my $theme_dest = Path::Tiny->new( $dir );
    my $theme_root = Path::Tiny->new( dist_dir( 'Statocles' ), 'theme', $name );

    my $iter = $theme_root->iterator({ recurse => 1 });
    while ( my $path = $iter->() ) {
        next unless $path->is_file;
        my $relative = $path->relative( $theme_root );
        my $dest = $theme_dest->child( $relative );
        # Don't overwrite site-customized hooks
        next if ( $path->stat->size == 0 && $dest->exists );
        $dest->remove if $dest->exists;
        $dest->parent->mkpath;
        $path->copy( $dest );
    }
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
    use File::Share qw( dist_dir );
    has 'site';

    sub startup {
        my ( $self ) = @_;
        $self->log( $self->site->log );

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
        unshift @{ $self->static->paths }, $self->site->build_store->path;

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
            my $build_dir = $self->site->build_store->path->realpath;

            for my $path ( keys %watches ) {
                $self->log->info( "Watching for changes in '$path'" );

                my $fs = Mac::FSEvents->new( {
                    path => "$path",
                    latency => 1.0,
                } );

                my $handle = $fs->watch;
                $ioloop->reactor->io( $handle, sub {
                    my ( $reactor, $writable ) = @_;

                    my $rebuild;
                    REBUILD:
                    while ( $reactor->is_readable( $handle ) ) {
                        for my $event ( $fs->read_events ) {
                            if ( $event->path =~ /^\Q$build_dir/ ) {
                                next;
                            }

                            $self->log->info( "Path '" . $event->path . "' changed... Rebuilding" );
                            $_->clear for @{ $watches{ $path } };
                            $rebuild = 1;
                        }
                    }

                    if ( $rebuild ) {
                        $self->site->build;
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

            my $asset = $self->static->file( $path );
            if ( !$asset ) {
                # Check for index.html
                $path = Mojo::Path->new( $c->stash->{path} . "/index.html" );
                $asset = $self->static->file( $path );
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

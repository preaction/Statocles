package Statocles::Command::daemon;
our $VERSION = '2.000';
# ABSTRACT: Run a server to test a Statocles website

=encoding utf8

=head1 SYNOPSIS

  Usage: statocles daemon [OPTIONS]

    statocles daemon
    statocles daemon -m production -l https://*:443 -l http://[::]:3000
    statocles daemon -l 'https://*:443?cert=./server.crt&key=./server.key'
    statocles daemon -w /usr/local/lib -w public -w myapp.conf

  Options:
    -b, --backend <name>           Morbo backend to use for reloading, defaults
                                   to "Poll"
    -h, --help                     Show this message
    -l, --listen <location>        One or more locations you want to listen on,
                                   defaults to the value of MOJO_LISTEN or
                                   "http://*:3000"
    -m, --mode <name>              Operating mode for your application,
                                   defaults to the value of
                                   MOJO_MODE/PLACK_ENV or "development"
    -v, --verbose                  Print details about what files changed to
                                   STDOUT
    -w, --watch <directory/file>   One or more directories and files to watch
                                   for changes, defaults to the application
                                   script as well as the "lib" and "templates"
                                   directories in the current working
                                   directory

=head1 DESCRIPTION

This command uses the L<Mojo::Server::Morbo> development server to
host a test of your website. Morbo automatically restarts when data
is changed in order for you to see the new data.

=head1 ATTRIBUTES

L<Statocles::Command::daemon> inherits all attributes from
L<Mojolicious::Command> and implements the following new ones.

=head2 description

  my $description = $daemon->description;
  $daemon         = $daemon->description('Foo');

Short description of this command, used for the command list.

=head2 usage

  my $usage = $daemon->usage;
  $daemon   = $daemon->usage('Foo');

Usage information for this command, used for the help screen.

=head1 METHODS

L<Statocles::Command::daemon> inherits all methods from
L<Mojolicious::Command> and implements the following new ones.

=head2 run

  $daemon->run(@ARGV);

Run this command.

=head1 SEE ALSO

L<Statocles>

=cut

use Mojo::Base 'Mojolicious::Command';

use Mojo::Server::Morbo;
use Mojo::Util 'getopt';
use Mojo::File qw( path );

has description => 'Start test server with auto-restart';
has usage       => sub { shift->extract_usage };

sub run {
    my ($self, @args) = @_;

    # XXX: This makes Morbo restart for any change anywhere. This works
    # with the AutoReload plugin, but it's slow. We should find a way to
    # make only those directories that are required to be reloaded, and
    # add a way for the AutoReload plugin to tell a browser to refresh.
    my @watch = path();

    getopt
      'b|backend=s' => \$ENV{MOJO_MORBO_BACKEND},
      'l|listen=s'  => \my @listen,
      'm|mode=s'    => \$ENV{MOJO_MODE},
      'v|verbose'   => \$ENV{MORBO_VERBOSE},
      'w|watch=s'   => \@watch;

    my $morbo = Mojo::Server::Morbo->new;
    $morbo->daemon->listen(\@listen) if @listen;
    $morbo->backend->watch(\@watch)  if @watch;
    $morbo->run( $0 );
}

1;

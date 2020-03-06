package Statocles;
our $VERSION = '0.097';
# ABSTRACT: A static site generator

use Statocles::Base 'Class';
use Scalar::Util qw( blessed );
use Getopt::Long qw( GetOptionsFromArray :config pass_through bundling no_auto_abbrev );
use Pod::Usage::Return qw( pod2usage );
use Beam::Wire;
use Mojo::Loader qw( load_class );

my @VERBOSE = ( "warn", "info", "debug", "trace" );

=attr site

The L<site|Statocles::Site> we're working with.

=cut

has site => (
    is => 'ro',
    isa => InstanceOf['Statocles::Site'],
);

=method run

    my $exitval = $cmd->run( @argv );

Run the command given in @argv. See L<statocles> for a list of commands and
options.

=cut

sub run {
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
        'include|I:s@',
    );
    return pod2usage(0) if $opt{help};

    if ( $opt{version} || ( $opt{verbose} && !@argv ) ) {
        say "Statocles version $Statocles::VERSION (Perl $^V)";
        require POSIX;
        say "Locale: " . POSIX::setlocale( POSIX::LC_CTYPE );
        return 0;
    }

    if ( $opt{include} ) {
        unshift @INC, @{ $opt{include} };
    }

    my $method = shift @argv;
    return pod2usage("ERROR: Missing command") unless $method;

    # Create site does not require a config file
    if ( $method eq 'create' ) {
        require Statocles::Command::create;
        return Statocles::Command::create->new->run( @argv );
    }

    my ( $exit, $site ) = _load_site( %opt );
    if ( $exit ) {
        return $exit;
    }

    if ( $opt{verbose} ) {
        $site->log->handle( \*STDOUT );
        $site->log->level( $VERBOSE[ $opt{verbose} ] );
    }

    my $cmd_class = 'Statocles::Command::' . $method;

    my $error = load_class( $cmd_class );
    if ( $error ) {
        if ( my $app = $site->apps->{ $method } ) {
            if ( !$app->can( 'command' ) ) {
                say STDERR sprintf 'ERROR: Application "%s" has no commands', $method;
                return 1;
            }
            return $app->command( $method, @argv );
        }
        else {
            return pod2usage("ERROR: Unknown command or app '$method'");
        }
    }

    my $cmd = $cmd_class->new( site => $site );
    return $cmd->run( @argv );
}

sub _load_site {
    my ( %opt ) = @_;
    if ( !-e $opt{config} ) {
        warn sprintf qq{ERROR: Could not find config file "\%s"\n}, $opt{config};
        return 1;
    }

    my $wire = eval { Beam::Wire->new( file => $opt{config} ) };

    if ( $@ ) {
        if ( blessed $@ && $@->isa( 'Beam::Wire::Exception::Config' ) ) {
            my $remedy;
            if ( $@ =~ /found character that cannot start any token/ || $@ =~ /YAML_PARSE_ERR_NONSPACE_INDENTATION/ ) {
                $remedy = "Check that you are not using tabs for indentation. ";
            }
            elsif ( $@ =~ /did not find expected key/ || $@ =~ /YAML_PARSE_ERR_INCONSISTENT_INDENTATION/ ) {
                $remedy = "Check your indentation. ";
            }
            elsif ( $@ =~ /Syck parser/ && $@ =~ /syntax error/ ) {
                $remedy = "Check your indentation. ";
            }

            my $more_info = ( !$opt{verbose} ? qq{run with the "--verbose" option or } : "" )
                          . "check Statocles::Help::Error";

            warn sprintf qq{ERROR: Could not load config file "%s". %sFor more information, %s.%s},
                $opt{config},
                $remedy,
                $more_info,
                ( $opt{verbose} ? "\n\nRaw error: $@" : "" )
                ;

            return 1;
        }
        die $@;
    }

    my $site = eval { $wire->get( $opt{site} ) };

    if ( $@ ) {
        if ( blessed $@ && $@->isa( 'Beam::Wire::Exception::NotFound' ) && $@->name eq $opt{site} ) {
            warn sprintf qq{ERROR: Could not find site named "%s" in config file "%s"\n},
                $opt{site}, $opt{config};
            return 1;
        }
        warn sprintf qq{ERROR: Could not create site object "%s" in config file "%s": %s\n},
            $opt{site}, $opt{config}, $@;
        return 1;
    }

    return ( 0, $site );
}

sub log {
    my ( $invocant, $level, @args ) = @_;
    use Mojo::Log;
    state $log = Mojo::Log->new( level => $ENV{MOJO_LOG_LEVEL} // 'info' );
    if ( $level && @args ) {
        return $log->$level( @args );
    }
    return $log;
}

1;
__END__

=head1 SYNOPSIS

    # Create a new site
    statocles create www.example.com

    # Create a new blog post
    export EDITOR=vim
    statocles blog post

    # Build the site
    statocles build

    # Test the site in a local web browser
    statocles daemon

    # Deploy the site
    statocles deploy

=head1 DESCRIPTION

Statocles is an application for building static web pages from a set of plain
YAML and Markdown files. It is designed to make it as simple as possible to
develop rich web content using basic text-based tools.

=head2 FEATURES

=over

=item *

A simple format based on
L<Markdown|http://daringfireball.net/projects/markdown/> for editing site
content.

=item *

A command-line application for building, deploying, and editing the site.

=item *

A simple daemon to display a test site before it goes live.

=item *

A L<blogging application|Statocles::App::Blog#FEATURES> with

=over

=item *

RSS and Atom syndication feeds.

=item *

Tags to organize blog posts. Tags have their own custom feeds.

=item *

Crosspost links to direct users to a syndicated blog.

=item *

Post-dated blog posts to appear automatically when the date is passed.

=back

=item *

Customizable L<themes|Statocles::Theme> using L<the Mojolicious template
language|Mojo::Template#SYNTAX>.

=item *

A clean default theme using L<the Skeleton CSS library|http://getskeleton.com>.

=item *

SEO-friendly features such as L<sitemaps (sitemap.xml)|http://www.sitemaps.org>.

=item *

L<Automatic checking for broken links|Statocles::Plugin::LinkCheck>.

=item *

L<Syntax highlighting|Statocles::Plugin::Highlight> for code and configuration blocks.

=item *

Hooks to add L<your own plugins|Statocles::Plugin> and L<your own custom
applications|Statocles::App>.

=back

=head1 GETTING STARTED

To get started with Statocles, L<consult the Statocles::Help guides|Statocles::Help>.

=head1 SEE ALSO

For news and documentation, L<visit the Statocles website at
http://preaction.me/statocles|http://preaction.me/statocles>.

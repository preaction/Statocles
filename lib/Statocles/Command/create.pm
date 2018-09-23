package Statocles::Command::create;
our $VERSION = '0.094';
# ABSTRACT: The command to create new Statocles site

use Statocles::Base 'Command';
use Statocles::Command::bundle;
use Statocles::Template;
use File::Share qw( dist_dir );

sub run {
    my ( $self, @argv ) = @_;
    $self->create_site( \@argv );
}

sub create_site {
    my ( $self, $argv ) = @_;

    my %answer;
    my $site_root = '.';

    # Allow the user to set the base URL and the site folder as an argument
    if ( @$argv ) {
        my $base = $argv->[0];
        if ( $base =~ m{^https?://(.+)} ) {
            $answer{base_url} = $base;
            $site_root = $argv->[1] || $1;
        }
        else {
            $answer{base_url} = "http://$base";
            $site_root = $argv->[1] || $base;
        }
    }

    my $create_dir = Path::Tiny->new( dist_dir( 'Statocles' ) )->child( 'create' );
    my $question = YAML::Load( $create_dir->child( 'script.yml' )->slurp_utf8 );
    my %prompt = (
        flavor => 'Which flavor of site would you like? ([1], 2, 0)',
        bundle_theme => 'Do you want to bundle the theme? ([Y]/n)',
        base_url => 'What is the URL where the site will be deployed?',
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

    if ( !$answer{base_url} ) {
        print "\n", "\n", $question->{base_url};
        print "\n", "\n", $prompt{base_url}, " ";
        chomp( $answer{base_url} = <STDIN> );
        if ( $answer{base_url} !~ m{^https?://} ) {
            $answer{base_url} = "http://$answer{base_url}";
        }
    }

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
    my $cwd = cwd;
    my $root = Path::Tiny->new( $site_root );
    $root->mkpath;
    my $config_tmpl = Statocles::Template->new(
        path => $create_dir->child( 'site.yml' ),
    );
    my %vars;

    if ( $answer{flavor} == 1 ) {
        $vars{site}{index} = "/blog";
        $vars{site}{nav}{main}[0] = {
            href => "/",
            text => "Blog",
        };
    }
    elsif ( $answer{flavor} == 2 ) {
        $vars{site}{index} = "/";
        $vars{site}{nav}{main}[0] = {
            href => "/blog",
            text => "Blog",
        };
    }
    else {
        $vars{site}{index} = "/blog";
        $vars{site}{nav}{main}[0] = {
            href => "/",
            text => "Blog",
        };
    }

    if ( lc $answer{bundle_theme} eq 'y' ) {
        chdir $root;
        Statocles::Command::bundle->bundle_theme( 'default', 'theme' );
        chdir $cwd;
        $vars{theme}{store} = 'theme';
    }
    else {
        $vars{theme}{store} = '::default';
    }

    if ( $answer{base_url} ) {
        $vars{site}{base_url} = $answer{base_url};
    }

    if ( $answer{deploy_class} == 1 ) {
        $vars{deploy}{'$class'} = 'Statocles::Deploy::Git';
        $vars{deploy}{branch} = $answer{git_branch};

        # Create the git repo
        require Git::Repository;
        # Running init more than once is apparently completely safe, so we don't
        # even have to check before we run it
        chdir $root;
        Git::Repository->run( 'init' );
        chdir $cwd;
        $root->child( '.gitignore' )->append( "\n.statocles\n" );
    }
    elsif ( $answer{deploy_class} == 2 ) {
        $vars{deploy}{'$class'} = 'Statocles::Deploy::File';
        $vars{deploy}{path} = $answer{deploy_path};
    }
    else {
        # We need a deploy in order to create a Site object
        $vars{deploy}{'$class'} = 'Statocles::Deploy::File';
        $vars{deploy}{path} = '.';
    }

    $root->child( 'site.yml' )->spew_utf8( $config_tmpl->render( %vars ) );
    my ( $site ) = YAML::Load( $root->child( 'site.yml' )->slurp_utf8 );

    # Make required store directories
    for my $app ( map { $_->{'$ref'} } values %{ $site->{site}{apps} } ) {
        my $path = $site->{$app}{store};
        next unless $path;
        $root->child( $path )->mkpath;
    }

    ### Copy initial site content
    # Blog
    if ( my $ref = $site->{site}{apps}{blog} ) {
        my $path = $site->{blog_app}{url_root};
        my ( undef, undef, undef, $day, $mon, $year ) = localtime;
        $year += 1900;
        $mon += 1;

        my @date_parts = (
            sprintf( '%04i', $year ),
            sprintf( '%02i', $mon ),
            sprintf( '%02i', $day ),
        );

        my $post_path = $root->child( $path, @date_parts, 'first-post', 'index.markdown' );
        $post_path->parent->mkpath;
        $create_dir->child( 'blog', 'post.markdown' )->copy( $post_path );
    }
    my $page_path = $root->child( 'index.markdown' );
    $page_path->parent->mkpath;
    $create_dir->child( 'page', 'index.markdown' )->copy( $page_path );

    ### DONE!
    print "\n", "\n", $question->{finish}, "\n", "\n";

    return 0;
}

1;

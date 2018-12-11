
use v5.14;
use warnings;
use YAML ( );
use Mojo::File qw( path );

# Upgrade the site in the current directory
# Read the config file
my $config = YAML::LoadFile( 'site.yml' );

# Find the blog app
my $site_conf = $config->{site};
if ( !$site_conf->{ '$class' } ) {
    $site_conf = $site_conf->{args};
}

my $blog_conf = $site_conf->{apps}{blog};
if ( $blog_conf->{ '$ref' } ) {
    $blog_conf = $config->{ $blog_conf->{ '$ref' } };
}
if ( !$blog_conf->{ '$class' } ) {
    $blog_conf = $blog_conf->{args};
}
if ( $blog_conf->{store} ) {
    say qq{Found blog directory: $blog_conf->{store}};
    say qq{Adding dates to all blog entries};
    path( $blog_conf->{store} )->list_tree->each( sub {
        my ( $path ) = @_;
        if ( $path =~ m{/(\d{4})/(\d{2})/(\d{2})/[^/]+/index[.](?:markdown|md)} ) {
            my $date = join '-', $1, $2, $3;
            say qq{\t$path: $date};
            my $content = $path->slurp;
            $content =~ s{---\n}{---\ndate: $date\n}sm;
            $path->spurt( $content );
        }
    } );
}

# Fix the config file
# Main nav title is now text

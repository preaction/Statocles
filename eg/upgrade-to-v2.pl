
use v5.14;
use warnings;
use Data::Dumper;
use Beam::Wire;
use Mojo::File qw( path );

if ( !-e 'site.yml' ) {
    die "No 'site.yml' config found. This must be run in a Statocles content directory.";
}

my %new_config = (
);

my $wire = Beam::Wire->new( file => 'site.yml' );

my $old_site = $wire->normalize_config( $wire->get_config( 'site' ) );

# Migrate main navigation
# Mention that any other navigations should now be added to an
# appropriate layout section

for my $app_name ( keys %{ $old_site->{args}{apps} } ) {
    my $app = $old_site->{args}{apps}{ $app_name };
    if ( my $ref = $app->{ '$ref' } ) {
        $app = $wire->normalize_config( $wire->get_config( $ref ) );
    }

    if ( $app->{class} eq 'Statocles::App::Blog' ) {
        say sprintf 'Migrating app %s (%s)', $app_name, $app->{args}{url_root};
        # Find the blogs and add them to the new config
        $new_config{apps}{ $app_name } = {
            route => $app->{args}{url_root},
            app => 'blog',
        };

        # Find the posts inside the blogs and add dates to them
        my $path = path( $app->{args}{store} );
        for my $file ( $path->list_tree->each ) {
            next unless $file =~ m{\.(?:markdown|md)$};
            next unless my ( $y, $m, $d ) = $file =~ m{/(\d{4})/(\d{2})/(\d{2})/};
            my $date = join '-', $y, $m, $d;

            my $content = $file->slurp;
            next if $content =~ m{\A (?:---)? .+ ^date: .+ ^---$ }msx;

            say sprintf qq{\tAdding date %s to %s}, $date, $file;
            $content =~ s{\A ((?:---)? .* ^title: [^\n]+) \n }{$1\ndate: $date\n}msx;
            $file->spurt( $content );
        }
    }
}

say sprintf 'Writing config: statocles.conf';
local $Data::Dumper::Indent = 1;
local $Data::Dumper::Trailingcomma = 1;
local $Data::Dumper::Deepcopy = 1;
local $Data::Dumper::Sortkeys = 1;
local $Data::Dumper::Quotekeys = 0;
my $conf = Dumper \%new_config;
$conf =~ s{^\$VAR[^\{]+}{};
path( 'statocles.conf' )->spurt( $conf );


package Statocles::Command::build;
our $VERSION = '0.097';
# ABSTRACT: Build the site in a directory

use Statocles::Base 'Command';

sub run {
    my ( $self, @argv ) = @_;
    my %build_opt;
    GetOptionsFromArray( \@argv, \%build_opt,
        'date|d=s',
        'base_url|base=s',
    );

    my $path = Path::Tiny->new( $argv[0] // '.statocles/build' );
    $path->mkpath;

    my $store = StoreType->coercion->( $path );
    #; say "Building site at " . $store->path;

    # Remove all pages from the build directory first
    $_->remove_tree for $store->path->children;

    my @pages = $self->site->pages( %build_opt );
    for my $page ( @pages ) {
        $store->write_file( $page->path, $page->has_dom ? $page->dom : $page->render );
    }

    return 0;
}

1;

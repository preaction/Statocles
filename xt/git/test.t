
use Statocles::Base;
use Path::Tiny qw( path );
use FindBin qw( $Bin );

my $bin = path( $Bin );

for my $version ( $bin->child( 'versions' )->children ) {
    local $ENV{PATH} = "$version/bin:$ENV{PATH}";
    system $^X, 't/deploy/git.t';
}


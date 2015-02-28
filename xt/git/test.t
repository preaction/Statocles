
use Statocles::Base 'Test';
use Capture::Tiny qw( capture_merged );
use Path::Tiny qw( path );
use FindBin qw( $Bin );

my $bin = path( $Bin );

plan skip_all => 'No additional git versions installed'
    unless $bin->child( 'versions' )->is_dir;

for my $version ( $bin->child( 'versions' )->children ) {
    next unless $version->child( 'bin', 'git' )->exists;
    my $exit;
    subtest 'Git version: ' . $version => sub {
        local $ENV{PATH} = "$version/bin:$ENV{PATH}";
        for my $t ( qw( t/deploy/git.t t/command/create.t ) ) {
            ( my $output, $exit ) = capture_merged { system $^X, $t };
            is $exit, 0, "test '$t' passed" or diag $output;
        }
    };
    last if $exit;
}

done_testing;

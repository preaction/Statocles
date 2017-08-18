package My::Test::Statocles::Store::Archive::Tar;

use Test::Lib;
use My::Test;

use My::Test::Store;
use Storable 'dclone';

my $SHARE_DIR = path( __DIR__, '..', 'share' );

use Archive::Tar;

my %default_args;

$default_args{archive_root}  = $SHARE_DIR;
$default_args{archive_strip} = $default_args{archive_root}->relative( cwd );

my $archive = Archive::Tar->new;
$default_args{archive_root}->relative( cwd )->visit(
    sub {
        $archive->add_files( $_[0] ) if $_[0]->is_file;
    },
    { recurse => 1 },
);

use Moo;

with 'My::Test::Store';

has '+class' => ( is => 'ro',
                  default => 'Statocles::Store::Archive::Tar'
                  );

has '+share_dir' => ( is => 'ro',
                      default => sub { $SHARE_DIR }
                  );


sub args {

    my $self = shift;

    my %arg = ( %default_args, @_ );

    my $path = path( $arg{path} );
    $path = $path->realpath if $path->exists;
    my $archive_root = $arg{archive_root}->realpath;

    # sometimes the test path is not a subdirectory of $SHARE_DIR,
    # indicating that it is doing something which doesn't use the
    # provided documents. Create an empty archive for the test to
    # play with.

    unless ( $archive_root->subsumes( $path ) ) {
        $arg{archive_root} = $arg{path};
        $arg{archive}      = Archive::Tar->new;
    }
    else {
        $arg{archive} = dclone( $archive );
    }

    return \%arg;
}

sub required {

    my $self = shift;
    my $args = $self->args( @_ );

    delete $args->{archive_strip};

    return $args;
}

__PACKAGE__->new->run_tests;

done_testing;

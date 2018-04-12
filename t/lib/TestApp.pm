package
    TestApp;

use Statocles::Base 'Class';
use Scalar::Util qw( blessed );
use Statocles::Page::Plain;
with 'Statocles::Role::App';

has _pages => (
    is => 'ro',
    isa => ArrayRef[ConsumerOf['Statocles::Role::Page']|HashRef],
    init_arg => 'pages',
    default => sub { [] },
);

has last_pages_args => ( is => 'rw' );

sub pages {
    my ( $self, @args ) = @_;
    $self->last_pages_args( \@args );
    my @pages =
        map { blessed $_ ? $_ : ( $_->{class} || "Statocles::Page::Plain" )->new( %$_ ) }
        @{ $self->_pages }
        ;
    #; say "Returning pages: " . join "; ", map { $_->path } @pages;
    return @pages;
}

1;


package
    TestApp;

use Statocles::Base 'Class';
use Scalar::Util qw( blessed );
use Statocles::Page::Plain;
with 'Statocles::App';

has _pages => (
    is => 'ro',
    isa => ArrayRef[ConsumerOf['Statocles::Page']|HashRef],
    init_arg => 'pages',
    default => sub { [] },
);

sub pages {
    my ( $self ) = @_;
    return map { blessed $_ ? $_ : Statocles::Page::Plain->new( %$_ ) } @{ $self->_pages };
}

1;


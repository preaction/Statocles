package
    TestApp;

use Statocles::Base 'Class';
with 'Statocles::App';

has _pages => (
    is => 'ro',
    isa => ArrayRef[ConsumerOf['Statocles::Page']],
    init_arg => 'pages',
    default => sub { [] },
);

sub pages {
    my ( $self ) = @_;
    return @{ $self->_pages };
}

1;


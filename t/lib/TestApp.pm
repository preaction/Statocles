package
    TestApp;

use Statocles::Base 'Class';
with 'Statocles::App';

has _pages => (
    is => 'ro',
    isa => ArrayRef[ConsumerOf['Statocles::Page']],
    required => 1,
    init_arg => 'pages',
);

sub pages {
    my ( $self ) = @_;
    return @{ $self->_pages };
}

1;


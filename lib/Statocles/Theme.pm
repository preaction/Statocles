package Statocles::Theme;
# ABSTRACT: Templates, headers, footers, and navigation

use Statocles::Class;
use File::Find qw( find );

has source_dir => (
    is => 'ro',
    isa => Str,
);

has templates => (
    is => 'ro',
    isa => HashRef[HashRef[InstanceOf['Text::Template']]],
    lazy => 1,
    builder => 'read',
);

sub read {
    my ( $self ) = @_;
    my %tmpl;
    find(
        sub {
            if ( /[.]tmpl$/ ) {
                my ( $vol, $dirs, $name ) = splitpath( $File::Find::name );
                $name =~ s/[.]tmpl$//;
                my @dirs = splitdir( $dirs );
                # $dirs will end with a slash, so the last item in @dirs is ''
                my $group = $dirs[-2];
                $tmpl{ $group }{ $name } = Text::Template->new(
                    TYPE => 'FILE',
                    SOURCE => $File::Find::name,
                ) or die "Could not make template: $Text::Template::ERROR";
            }
        },
        $self->source_dir,
    );
    return \%tmpl;
}

sub template {
    my ( $self, $app, $template ) = @_;
    return $self->templates->{ $app }{ $template };
}

1;
__END__

=head1 DESCRIPTION

A Theme contains all the templates that applications need.



package ArtistSite::LyricSection;

use v5.26;
use warnings;

use Moo;

has type => (
    is       => 'ro',
    required => 1,
);

has lines => (
    is       => 'ro',
    required => 1,
);

sub label {
    my ($self) = @_;

    return join ' ', map { ucfirst } split /[-_]/, $self->type;
}

1;

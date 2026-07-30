package ArtistSite::ValidationIssue;

use v5.26;
use warnings;

use Moo;

has severity => (
    is       => 'ro',
    required => 1,
);

has code => (
    is       => 'ro',
    required => 1,
);

has message => (
    is       => 'ro',
    required => 1,
);

sub is_error {
    my ($self) = @_;

    return $self->severity eq 'error';
}

sub as_string {
    my ($self) = @_;

    return uc($self->severity) . ' [' . $self->code . '] '
        . $self->message;
}

1;

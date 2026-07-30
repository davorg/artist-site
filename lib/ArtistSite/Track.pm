package ArtistSite::Track;

use v5.26;
use warnings;

use Moo;

has position => (
    is       => 'ro',
    required => 1,
);

has song => (
    is => 'ro',
);

has status => (
    is      => 'lazy',
    builder => '_build_status',
);

has unannounced_label => (
    is       => 'ro',
    required => 1,
);

sub _build_status {
    my ($self) = @_;

    return defined $self->song ? 'announced' : 'unannounced';
}

sub BUILD {
    my ($self) = @_;

    my %valid_status = map { $_ => 1 } qw(unannounced announced released);

    die "Unknown track status '" . $self->status . "'"
        unless $valid_status{$self->status};

    die 'An announced or released track must reference a song'
        if $self->status ne 'unannounced' && !defined $self->song;

    return;
}

sub is_unannounced {
    my ($self) = @_;

    return $self->status eq 'unannounced';
}

sub display_title {
    my ($self) = @_;

    return $self->unannounced_label if $self->is_unannounced;
    return $self->song->title;
}

sub title {
    my ($self) = @_;

    return $self->display_title;
}

sub lyrics {
    my ($self) = @_;

    return [] unless defined $self->song;
    return $self->song->lyrics;
}

1;

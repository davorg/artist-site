package ArtistSite::Artist;

use v5.26;
use warnings;
use utf8;

use Moo;

has name => (
    is       => 'ro',
    required => 1,
);

has tagline => (
    is       => 'ro',
    required => 1,
);

has description => (
    is       => 'ro',
    required => 1,
);

has about_title => (
    is      => 'lazy',
    builder => '_build_about_title',
);

has site_url => (
    is       => 'ro',
    required => 1,
);

has location => (
    is => 'ro',
);

has ga4_measurement_id => (
    is => 'ro',
);

has soundcloud_user => (
    is => 'ro',
);

has hero_image => (
    is => 'ro',
);

has hero_image_alt => (
    is      => 'lazy',
    builder => '_build_hero_image_alt',
);

has hero_image_width => (
    is => 'ro',
);

has hero_image_height => (
    is => 'ro',
);

has social_links => (
    is      => 'ro',
    default => sub { [] },
);

has unannounced_track_label => (
    is      => 'ro',
    default => sub { 'Unannounced' },
);

sub url_for {
    my ($self, $path) = @_;

    return $self->site_url . '/' if $path eq '/';
    return $self->site_url . $path;
}

sub hero_image_url {
    my ($self) = @_;

    return unless defined $self->hero_image;
    return '/assets/images/' . $self->hero_image;
}

sub _build_hero_image_alt {
    my ($self) = @_;

    return 'Picture of ' . $self->name;
}

sub _build_about_title {
    my ($self) = @_;

    return $self->tagline;
}

sub social_links_label {
    my ($self) = @_;

    return 'Follow ' . $self->name;
}

1;

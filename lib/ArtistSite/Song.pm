package ArtistSite::Song;

use v5.26;
use warnings;
use utf8;

use Moo;

extends 'ArtistSite::Page';

has slug => (
    is       => 'ro',
    required => 1,
);

has title => (
    is       => 'ro',
    required => 1,
);

has description => (
    is       => 'ro',
    required => 1,
);

has lyrics => (
    is       => 'ro',
    required => 1,
);

has story => (
    is => 'ro',
);

has artwork => (
    is => 'ro',
);

has links => (
    is => 'ro',
);

has releases => (
    is      => 'ro',
    default => sub { [] },
);

sub add_release {
    my ($self, $release) = @_;

    push $self->releases->@*, $release;

    return;
}

sub has_story {
    my ($self) = @_;

    return defined $self->story;
}

sub listening_release {
    my ($self) = @_;

    for my $release ($self->releases->@*) {
        return $release
            if $release->release_type eq 'single'
            && $release->links->items->@*;
    }

    for my $release ($self->releases->@*) {
        return $release if $release->links->items->@*;
    }

    return;
}

sub effective_artwork {
    my ($self) = @_;

    return $self->artwork if defined $self->artwork;

    my $release = $self->listening_release // $self->releases->[0];
    return unless defined $release;

    return $release->artwork;
}

sub has_artwork {
    my ($self) = @_;

    return defined $self->effective_artwork;
}

sub artwork_url {
    my ($self) = @_;
    my $artwork = $self->effective_artwork;

    return unless defined $artwork;
    return '/assets/images/' . $artwork->file;
}

sub effective_links {
    my ($self) = @_;

    return $self->links
        if defined $self->links && $self->links->items->@*;

    my $release = $self->listening_release;
    return unless defined $release;

    return $release->links;
}

sub spotify_embed_url {
    my ($self) = @_;
    my $links = $self->effective_links;

    return unless defined $links;
    return $links->spotify_embed_url;
}

sub streaming_links {
    my ($self) = @_;
    my $links = $self->effective_links;

    return [] unless defined $links;
    return $links->items;
}

sub og_image {
    my ($self) = @_;

    return $self->artist->url_for($self->social_image)
        if defined $self->social_image && $self->has_artwork;

    my $artwork_url = $self->artwork_url;

    return unless defined $artwork_url;
    return $self->artist->url_for($artwork_url);
}

sub og_image_alt {
    my ($self) = @_;
    my $artwork = $self->effective_artwork;

    return unless defined $artwork;
    return $artwork->alt;
}

sub json_ld_type {
    return 'MusicComposition';
}

sub json_ld_fields {
    return [
        {name        => 'title'},
        {url         => 'canonical_url'},
        {description => 'description'},
        {
            image => sub {
                my ($self) = @_;

                my $artwork_url = $self->artwork_url;
                return unless defined $artwork_url;

                return $self->artist->url_for($artwork_url);
            },
        },
        {
            composer => sub {
                my ($self) = @_;

                return {
                    '@type' => 'MusicGroup',
                    name    => $self->artist->name,
                };
            },
        },
    ];
}

1;

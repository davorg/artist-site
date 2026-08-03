package ArtistSite::Release;

use v5.26;
use warnings;
use utf8;

use Moo;

extends 'ArtistSite::Page';

has slug => (
    is       => 'ro',
    required => 1,
);

has release_date => (
    is => 'ro',
);

has release_type => (
    is       => 'ro',
    required => 1,
);

has tagline => (
    is       => 'ro',
    required => 1,
);

has artwork => (
    is       => 'ro',
    required => 1,
);

has streaming => (
    is       => 'ro',
    required => 1,
);

has tracks => (
    is       => 'ro',
    required => 1,
);

has unannounced_track_label => (
    is      => 'ro',
    default => sub { 'Unannounced' },
);

has featured => (
    is      => 'ro',
    default => sub { 0 },
);

sub type_label {
    my ($self) = @_;

    return {
        single => 'Single',
        ep     => 'EP',
        album  => 'Album',
    }->{$self->release_type} // ucfirst $self->release_type;
}

sub release_date_label {
    my ($self) = @_;

    return $self->release_date // 'Forthcoming';
}

sub primary_track {
    my ($self) = @_;

    return $self->tracks->[0];
}

sub has_multiple_tracks {
    my ($self) = @_;

    return $self->tracks->@* > 1;
}

sub lyric_track {
    my ($self) = @_;

    for my $track ($self->tracks->@*) {
        return $track if defined $track->song && $track->lyrics->@*;
    }

    return;
}

sub has_lyrics {
    my ($self) = @_;

    return defined $self->lyric_track;
}

sub og_type {
    my ($self) = @_;

    return $self->release_type eq 'single' ? 'music.song' : 'music.album';
}

sub artwork_url {
    my ($self) = @_;

    return '/assets/images/' . $self->artwork->file;
}

sub spotify_embed_url {
    my ($self) = @_;

    return $self->streaming->spotify_embed_url;
}

sub json_ld_type {
    my ($self) = @_;

    return $self->release_type eq 'single'
        ? 'MusicRecording'
        : 'MusicAlbum';
}

sub json_ld_fields {
    return [
        {name          => 'title'},
        {url           => 'canonical_url'},
        {description   => 'description'},
        {datePublished => 'release_date'},
        {
            image => sub {
                my ($self) = @_;

                return $self->artist->url_for($self->artwork_url);
            },
        },
        {
            byArtist => sub {
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

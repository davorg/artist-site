package ArtistSite::Streaming;

use v5.26;
use warnings;

use Moo;

has spotify => (
    is => 'ro',
);

has spotify_type => (
    is      => 'ro',
    default => sub { 'track' },
);

has soundcloud => (
    is => 'ro',
);

has soundcloud_type => (
    is      => 'ro',
    default => sub { 'track' },
);

has soundcloud_user => (
    is => 'ro',
);

has youtube => (
    is => 'ro',
);

sub items {
    my ($self) = @_;

    my @items = (
        ArtistSite::Streaming::Item->new(
            name   => 'YouTube',
            action => 'Watch',
            url    => $self->youtube_url,
        ),
        ArtistSite::Streaming::Item->new(
            name => 'Spotify',
            url  => $self->spotify_url,
        ),
        ArtistSite::Streaming::Item->new(
            name => 'SoundCloud',
            url  => $self->soundcloud_url,
        ),
    );

    return [grep { defined $_->url && length $_->url } @items];
}

sub spotify_url {
    my ($self) = @_;

    my $override_url = $self->_override_for('spotify', 'url');
    return $override_url if defined $override_url;

    my $spotify_id = $self->_id_for('spotify');
    my $spotify_type = $self->spotify_type;

    return undef
        unless defined $spotify_id
        && $spotify_id =~ /^[A-Za-z0-9]{22}$/
        && $spotify_type =~ /^(?:album|playlist|track)$/;

    return "https://open.spotify.com/$spotify_type/$spotify_id";
}

sub spotify_embed_url {
    my ($self) = @_;

    my $override_url = $self->_override_for('spotify', 'embed_url');
    return $override_url if defined $override_url;

    my $spotify_id = $self->_id_for('spotify');
    my $spotify_type = $self->spotify_type;

    if (defined $spotify_id
            && $spotify_id =~ /^[A-Za-z0-9]{22}$/
            && $spotify_type =~ /^(?:album|playlist|track)$/) {
        return "https://open.spotify.com/embed/$spotify_type/$spotify_id";
    }

    my $page_url = $self->_override_for('spotify', 'url');
    return undef unless defined $page_url;

    return undef unless $page_url =~ m{
        ^https://open\.spotify\.com/
        (?:intl-[^/]+/)?
        (album|playlist|track)/([A-Za-z0-9]{22})
        (?:[/?].*)?$
    }x;

    return "https://open.spotify.com/embed/$1/$2";
}

sub soundcloud_url {
    my ($self) = @_;

    my $override_url = $self->_override_for('soundcloud', 'url');
    return $override_url if defined $override_url;

    my $slug = $self->_id_for('soundcloud');
    my $user = $self->soundcloud_user;
    my $soundcloud_type = $self->soundcloud_type;

    return undef
        unless defined $slug
        && defined $user
        && $slug =~ /^[A-Za-z0-9_-]+$/
        && $user =~ /^[A-Za-z0-9_-]+$/
        && $soundcloud_type =~ /^(?:set|track)$/;

    my $path = $soundcloud_type eq 'set' ? "$user/sets/$slug" : "$user/$slug";
    return "https://soundcloud.com/$path";
}

sub youtube_url {
    my ($self) = @_;

    my $override_url = $self->_override_for('youtube', 'url');
    return $override_url if defined $override_url;

    my $video_id = $self->_id_for('youtube');

    return undef
        unless defined $video_id
        && $video_id =~ /^[A-Za-z0-9_-]{11}$/;

    return "https://www.youtube.com/watch?v=$video_id";
}

sub youtube_embed_url {
    my ($self) = @_;

    my $override_url = $self->_override_for('youtube', 'embed_url');
    return $override_url if defined $override_url;

    my $video_id = $self->_id_for('youtube');

    if (defined $video_id && $video_id =~ /^[A-Za-z0-9_-]{11}$/) {
        return "https://www.youtube.com/embed/$video_id";
    }

    my $page_url = $self->_override_for('youtube', 'url');
    return undef unless defined $page_url;

    $video_id = $1 if $page_url =~ m{
        ^https://(?:www\.)?youtube\.com/watch\?.*\bv=([A-Za-z0-9_-]{11})
    }x;
    $video_id = $1 if $page_url =~ m{
        ^https://youtu\.be/([A-Za-z0-9_-]{11})(?:[/?].*)?$
    }x;

    return undef unless defined $video_id;
    return "https://www.youtube.com/embed/$video_id";
}

sub _id_for {
    my ($self, $service) = @_;
    my $reference = $self->$service;

    return undef unless defined $reference;
    return $reference unless ref $reference;
    return undef unless ref $reference eq 'HASH';

    return $reference->{id};
}

sub _override_for {
    my ($self, $service, $field) = @_;
    my $reference = $self->$service;

    return undef unless ref $reference eq 'HASH';

    my $url = $reference->{$field};
    return undef unless defined $url && $url =~ m{^https://};

    return $url;
}

package ArtistSite::Streaming::Item;

use Moo;

has action => (
    is      => 'ro',
    default => sub { 'Listen' },
);

has name => (
    is       => 'ro',
    required => 1,
);

has url => (
    is => 'ro',
);

1;

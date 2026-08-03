package ArtistSite::StreamingLinks;

use v5.26;
use warnings;

use Moo;

has spotify => (
    is => 'ro',
);

has soundcloud => (
    is => 'ro',
);

has youtube => (
    is => 'ro',
);

sub items {
    my ($self) = @_;

    my @links = (
        ArtistSite::StreamingLinks::Item->new(
            name => 'YouTube',
            action => 'Watch',
            url  => $self->youtube_url,
        ),
        ArtistSite::StreamingLinks::Item->new(
            name => 'Spotify',
            url  => $self->spotify,
        ),
        ArtistSite::StreamingLinks::Item->new(
            name => 'SoundCloud',
            url  => $self->soundcloud,
        ),
    );

    return [grep { defined $_->url && length $_->url } @links];
}

sub youtube_url {
    my ($self) = @_;
    my $video_id = $self->youtube;

    return undef unless defined $video_id && $video_id =~ /^[A-Za-z0-9_-]{11}$/;
    return "https://www.youtube.com/watch?v=$video_id";
}

sub youtube_embed_url {
    my ($self) = @_;
    my $video_id = $self->youtube;

    return undef unless defined $video_id && $video_id =~ /^[A-Za-z0-9_-]{11}$/;
    return "https://www.youtube.com/embed/$video_id";
}

sub spotify_embed_url {
    my ($self) = @_;
    my $url = $self->spotify;

    return unless defined $url;

    return unless $url =~ m{
        spotify\.com/
        (?:intl-[^/]+/)?
        (track|album|playlist)/([A-Za-z0-9]+)
    }x;

    return "https://open.spotify.com/embed/$1/$2";
}

package ArtistSite::StreamingLinks::Item;

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

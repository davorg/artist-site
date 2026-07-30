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

sub items {
    my ($self) = @_;

    my @links = (
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

has name => (
    is       => 'ro',
    required => 1,
);

has url => (
    is => 'ro',
);

1;

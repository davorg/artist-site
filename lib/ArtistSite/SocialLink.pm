package ArtistSite::SocialLink;

use v5.26;
use warnings;

use Moo;

has service => (
    is       => 'ro',
    required => 1,
);

has url => (
    is       => 'ro',
    required => 1,
);

sub label {
    my ($self) = @_;

    return {
        instagram  => 'Instagram',
        tiktok     => 'TikTok',
        spotify    => 'Spotify',
        soundcloud => 'SoundCloud',
    }->{$self->service} // ucfirst $self->service;
}

sub icon_class {
    my ($self) = @_;

    return {
        instagram  => 'fa-brands fa-instagram',
        tiktok     => 'fa-brands fa-tiktok',
        spotify    => 'fa-brands fa-spotify',
        soundcloud => 'fa-brands fa-soundcloud',
    }->{$self->service} // 'fa-solid fa-arrow-up-right-from-square';
}

1;

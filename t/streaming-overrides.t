use v5.26;
use warnings;

use Test2::V0;
use FindBin;
use lib "$FindBin::Bin/../lib";

use ArtistSite::Streaming;

subtest 'explicit URL overrides' => sub {
    my $streaming = ArtistSite::Streaming->new(
        spotify => {
            url       => 'https://music.example/listen',
            embed_url => 'https://music.example/player',
        },
        soundcloud => {
            url => 'https://soundcloud.com/another-artist/unusual-location',
        },
        youtube => {
            url       => 'https://video.example/watch',
            embed_url => 'https://video.example/embed',
        },
    );

    is $streaming->spotify_url, 'https://music.example/listen',
        'uses an explicit Spotify link URL';
    is $streaming->spotify_embed_url, 'https://music.example/player',
        'uses an explicit Spotify embed URL';
    is $streaming->soundcloud_url,
        'https://soundcloud.com/another-artist/unusual-location',
        'uses an explicit SoundCloud URL without an artist user';
    is $streaming->youtube_url, 'https://video.example/watch',
        'uses an explicit YouTube link URL';
    is $streaming->youtube_embed_url, 'https://video.example/embed',
        'uses an explicit YouTube embed URL';
};

subtest 'recognised page URLs produce embeds' => sub {
    my $streaming = ArtistSite::Streaming->new(
        spotify => {
            url => 'https://open.spotify.com/track/4uLU6hMCjMI75M1A2tKUQC',
        },
        youtube => {
            url => 'https://www.youtube.com/watch?v=abcdefghijk',
        },
    );

    is $streaming->spotify_embed_url,
        'https://open.spotify.com/embed/track/4uLU6hMCjMI75M1A2tKUQC',
        'derives an embed from a recognised Spotify URL';
    is $streaming->youtube_embed_url,
        'https://www.youtube.com/embed/abcdefghijk',
        'derives an embed from a recognised YouTube URL';

    $streaming = ArtistSite::Streaming->new(
        youtube => {
            url => 'https://youtu.be/abcdefghijk',
        },
    );

    is $streaming->youtube_embed_url,
        'https://www.youtube.com/embed/abcdefghijk',
        'derives an embed from a shortened YouTube URL';
};

subtest 'identifier mappings' => sub {
    my $streaming = ArtistSite::Streaming->new(
        spotify => {
            id => '4uLU6hMCjMI75M1A2tKUQC',
        },
        soundcloud => {
            id => 'first-light',
        },
        soundcloud_user => 'exampleartist',
        youtube => {
            id => 'abcdefghijk',
        },
    );

    is $streaming->spotify_url,
        'https://open.spotify.com/track/4uLU6hMCjMI75M1A2tKUQC',
        'accepts an explicit Spotify ID mapping';
    is $streaming->soundcloud_url,
        'https://soundcloud.com/exampleartist/first-light',
        'accepts an explicit SoundCloud ID mapping';
    is $streaming->youtube_url,
        'https://www.youtube.com/watch?v=abcdefghijk',
        'accepts an explicit YouTube ID mapping';
};

subtest 'unsafe overrides are rejected' => sub {
    my $streaming = ArtistSite::Streaming->new(
        spotify => {
            url => 'javascript:alert(1)',
        },
        soundcloud => {
            url => 'http://soundcloud.example/insecure',
        },
    );

    is $streaming->items, [],
        'only accepts HTTPS override URLs';
};

done_testing;

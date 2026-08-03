use v5.26;
use warnings;

use Test2::V0;
use FindBin;
use lib "$FindBin::Bin/../lib";

use ArtistSite::Streaming;

subtest 'song streaming references' => sub {
    my $streaming = ArtistSite::Streaming->new(
        spotify        => '4uLU6hMCjMI75M1A2tKUQC',
        spotify_type   => 'track',
        soundcloud     => 'first-light',
        soundcloud_type => 'track',
        soundcloud_user => 'exampleartist',
        youtube         => 'abcdefghijk',
    );

    is $streaming->spotify_url,
        'https://open.spotify.com/track/4uLU6hMCjMI75M1A2tKUQC',
        'builds a Spotify track URL';
    is $streaming->spotify_embed_url,
        'https://open.spotify.com/embed/track/4uLU6hMCjMI75M1A2tKUQC',
        'builds a Spotify track embed URL';
    is $streaming->soundcloud_url,
        'https://soundcloud.com/exampleartist/first-light',
        'builds a SoundCloud track URL';
    is $streaming->youtube_url,
        'https://www.youtube.com/watch?v=abcdefghijk',
        'builds a YouTube watch URL';
    is $streaming->youtube_embed_url,
        'https://www.youtube.com/embed/abcdefghijk',
        'builds a YouTube embed URL';
    is [map { $_->name } $streaming->items->@*],
        ['YouTube', 'Spotify', 'SoundCloud'],
        'returns resolved streaming services';
};

subtest 'release streaming references' => sub {
    my $streaming = ArtistSite::Streaming->new(
        spotify         => '1111111111111111111111',
        spotify_type    => 'album',
        soundcloud      => 'four-sides',
        soundcloud_type => 'set',
        soundcloud_user => 'exampleartist',
    );

    is $streaming->spotify_url,
        'https://open.spotify.com/album/1111111111111111111111',
        'builds a Spotify album URL';
    is $streaming->soundcloud_url,
        'https://soundcloud.com/exampleartist/sets/four-sides',
        'builds a SoundCloud set URL';
};

subtest 'invalid references do not create links' => sub {
    my $streaming = ArtistSite::Streaming->new(
        spotify        => 'https://open.spotify.com/track/not-an-id',
        soundcloud     => 'not/a/slug',
        soundcloud_user => 'exampleartist',
        youtube         => 'too-short',
    );

    is $streaming->items, [], 'rejects malformed service references';

    $streaming = ArtistSite::Streaming->new(
        soundcloud => 'first-light',
    );

    ok !defined $streaming->soundcloud_url,
        'a SoundCloud slug requires an artist user';
};

done_testing;

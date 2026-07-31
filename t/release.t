use v5.26;
use warnings;
use utf8;

use Test2::V0;
use FindBin;
use lib "$FindBin::Bin/../lib";

use Path::Tiny qw(path);
use Template;

use ArtistSite::Artist;
use ArtistSite::Artwork;
use ArtistSite::Release;
use ArtistSite::Song;
use ArtistSite::StreamingLinks;
use ArtistSite::Track;

my $artist = ArtistSite::Artist->new(
    name        => 'Test Artist',
    tagline     => 'A tagline',
    description => 'Artist description',
    site_url    => 'https://example.com',
);

sub make_release {
    my ($spotify_url, @additional_tracks) = @_;

    my $song = ArtistSite::Song->new(
        artist      => $artist,
        url         => '/song/a-song/',
        template    => 'song.tt',
        slug        => 'a-song',
        title       => 'A Song',
        description => 'A song description',
        lyrics      => [],
    );

    my $track = ArtistSite::Track->new(
        position          => 1,
        song              => $song,
        status            => 'released',
        unannounced_label => $artist->unannounced_track_label,
    );

    return ArtistSite::Release->new(
        artist       => $artist,
        url          => '/release/a-song/',
        title        => 'A Song',
        template     => 'release.tt',
        description  => 'A song description',
        slug         => 'a-song',
        release_type => 'single',
        release_date => '2026-07-26',
        tagline      => 'A song tagline',
        artwork      => ArtistSite::Artwork->new(
            file   => 'a-song.webp',
            alt    => 'Cover artwork',
            width  => 1200,
            height => 1200,
        ),
        links => ArtistSite::StreamingLinks->new(
            spotify => $spotify_url,
        ),
        tracks => [$track, @additional_tracks],
    );
}

subtest 'release contains tracks, and tracks reference songs' => sub {
    my $release = make_release(undef);
    my $track = $release->primary_track;

    is $release->type_label, 'Single', 'human-readable release type';
    isa_ok $track, ['ArtistSite::Track'];
    isa_ok $track->song, ['ArtistSite::Song'];
    is $track->position, 1, 'track position';
    is $track->title, 'A Song', 'track delegates its title to the song';
    ok !$release->has_multiple_tracks, 'single has one track';
};

subtest 'unannounced tracks' => sub {
    is $artist->unannounced_track_label, 'Unannounced',
        'artist uses the engine default';

    my $track = ArtistSite::Track->new(
        position          => 2,
        status            => 'unannounced',
        unannounced_label => 'Waiting in the wings…',
    );

    ok $track->is_unannounced, 'track is unannounced';
    ok !defined $track->song, 'unannounced track needs no song';
    is $track->display_title, 'Waiting in the wings…',
        'track displays its configured placeholder';
    is $track->lyrics, [], 'unannounced track has no lyrics';

    like dies {
        ArtistSite::Track->new(
            position          => 3,
            status            => 'announced',
            unannounced_label => 'Still dreaming…',
        );
    }, qr{must reference a song},
        'announced track must reference a song';
};

subtest 'unannounced track rendering' => sub {
    my $unannounced_track = ArtistSite::Track->new(
        position          => 2,
        status            => 'unannounced',
        unannounced_label => 'Waiting in the wings…',
    );
    my $release = make_release(undef, $unannounced_track);
    my $template = Template->new({
        INCLUDE_PATH => path($FindBin::Bin)->parent->child('templates')->stringify,
        ENCODING     => 'utf8',
    });
    my $html = '';

    $template->process('release.tt', {page => $release}, \$html)
        or die $template->error;

    like $html, qr{class="track track--unannounced"},
        'marks the unannounced track';
    like $html, qr{Track 2, title not yet announced},
        'provides an accessible description';
    like $html, qr{Waiting in the wings…},
        'renders the configured placeholder';
};

subtest 'Spotify embed URLs' => sub {
    my $release = make_release(
        'https://open.spotify.com/track/4uLU6hMCjMI75M1A2tKUQC'
    );

    is $release->spotify_embed_url,
        'https://open.spotify.com/embed/track/4uLU6hMCjMI75M1A2tKUQC',
        'converts a Spotify track URL';

    $release = make_release(
        'https://open.spotify.com/intl-en/track/4uLU6hMCjMI75M1A2tKUQC'
    );

    is $release->spotify_embed_url,
        'https://open.spotify.com/embed/track/4uLU6hMCjMI75M1A2tKUQC',
        'converts a locale-prefixed Spotify URL';

    ok !defined make_release('https://example.com/song')->spotify_embed_url,
        'rejects a non-Spotify URL';
    ok !defined make_release(undef)->spotify_embed_url,
        'handles a missing Spotify URL';
};

subtest 'release structured data' => sub {
    my $json_ld = make_release(undef)->json_ld_data;

    is $json_ld->{'@type'}, 'MusicRecording', 'JSON-LD type';
    is $json_ld->{name}, 'A Song', 'JSON-LD name';
    is $json_ld->{datePublished}, '2026-07-26', 'publication date';
    is $json_ld->{byArtist}{name}, 'Test Artist', 'artist name';
    is $json_ld->{image}, 'https://example.com/assets/images/a-song.webp',
        'absolute artwork URL';
};

done_testing;

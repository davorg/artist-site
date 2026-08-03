use v5.26;
use warnings;

use Test2::V0;
use FindBin;
use lib "$FindBin::Bin/../lib";
use Path::Tiny qw(path);
use Template;

use ArtistSite::Artist;
use ArtistSite::Artwork;
use ArtistSite::Song;
use ArtistSite::StreamingLinks;
use ArtistSite::Story;
use ArtistSite::StorySection;

my $artist = ArtistSite::Artist->new(
    name        => 'Test Artist',
    tagline     => 'A tagline',
    description => 'Artist description',
    site_url    => 'https://example.com',
);

my $song = ArtistSite::Song->new(
    artist      => $artist,
    url         => '/song/a-song/',
    template    => 'song.tt',
    slug        => 'a-song',
    title       => 'A Song',
    description => 'A song description',
    lyrics      => [],
    artwork     => ArtistSite::Artwork->new(
        file   => 'a-song.webp',
        alt    => 'Artwork for A Song',
        width  => 1200,
        height => 1200,
    ),
    links => ArtistSite::StreamingLinks->new(
        youtube    => 'abcdefghijk',
        spotify   => 'https://open.spotify.com/track/4uLU6hMCjMI75M1A2tKUQC',
        soundcloud => 'https://soundcloud.com/example/a-song',
    ),
    story => ArtistSite::Story->new(
        intro => 'How the song began.',
        sections => [
            ArtistSite::StorySection->new(
                title      => 'In the studio',
                paragraphs => ['The first paragraph.', 'The second paragraph.'],
            ),
        ],
    ),
);

is $song->artwork_url, '/assets/images/a-song.webp',
    'uses song-specific artwork';
is $song->og_image, 'https://example.com/assets/images/a-song.webp',
    'uses song artwork in social metadata';
is $song->spotify_embed_url,
    'https://open.spotify.com/embed/track/4uLU6hMCjMI75M1A2tKUQC',
    'uses a song-specific Spotify link';
is $song->youtube_embed_url, 'https://www.youtube.com/embed/abcdefghijk',
    'builds a YouTube embed URL from the video ID';
is [map { $_->name } $song->streaming_links->@*],
    ['YouTube', 'Spotify', 'SoundCloud'], 'uses song-specific streaming links';
ok $song->has_story, 'song has a structured story';
is $song->story->sections->[0]->title, 'In the studio',
    'story contains section objects';

my $template = Template->new({
    INCLUDE_PATH => path($FindBin::Bin)->parent->child('templates')->stringify,
    ENCODING     => 'utf8',
});
my $html = '';
$template->process('song.tt', {page => $song}, \$html)
    or die $template->error;

like $html, qr{<h2>The story</h2>}, 'renders the story on the song page';
like $html, qr{<h3>In the studio</h3>}, 'renders story section titles';
like $html, qr{The first paragraph.*The second paragraph}s,
    'renders each story paragraph';
like $html, qr{src="https://www\.youtube\.com/embed/abcdefghijk"},
    'uses YouTube as the song player when a video ID is present';
unlike $html, qr{open\.spotify\.com/embed},
    'does not also render the Spotify player';
like $html, qr{href="https://www\.youtube\.com/watch\?v=abcdefghijk"},
    'includes the YouTube video in the song links';
like $html, qr{>\s*Watch on YouTube\s*<},
    'labels the YouTube link as a video action';

done_testing;

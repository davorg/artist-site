use v5.26;
use warnings;
use utf8;

use Test2::V0;
use FindBin;
use lib "$FindBin::Bin/../lib";

use Path::Tiny qw(path tempdir);
use Scalar::Util qw(refaddr);
use Image::Size qw(imgsize);

use ArtistSite::Artist;
use ArtistSite::Artwork;
use ArtistSite::LyricSection;
use ArtistSite::Page;
use ArtistSite::Release;
use ArtistSite::Site;
use ArtistSite::Song;
use ArtistSite::StreamingLinks;
use ArtistSite::Track;

my $project_root = path($FindBin::Bin)->parent;
my $fixture_root = path($FindBin::Bin)->child('fixtures');
my $output_dir = tempdir;

my $site = ArtistSite::Site->new(
    data_dir   => $fixture_root->child('data'),
    output_dir => $output_dir,
    theme_dir  => $project_root->child('templates'),
    assets_dir => $project_root->child('assets'),
    images_dir => $fixture_root->child('assets/images'),
);

$site->build;

subtest 'YAML data becomes domain objects' => sub {
    isa_ok $site->artist, ['ArtistSite::Artist'];
    is $site->artist->name, 'Example Artist', 'loads the artist data';

    ok $site->releases->@*, 'loads releases';
    ok $site->songs->@*, 'loads songs';
    isa_ok $site->songs->[0], ['ArtistSite::Song'];
    isa_ok $site->releases->[0], ['ArtistSite::Release'];
    my $seen_dated_release = 0;
    my $previous_date;
    for my $release ($site->releases->@*) {
        if (!defined $release->release_date) {
            ok !$seen_dated_release,
                'forthcoming releases precede dated releases';
            next;
        }

        $seen_dated_release = 1;
        ok $release->release_date le $previous_date,
            'dated releases are in reverse chronological order'
            if defined $previous_date;
        $previous_date = $release->release_date;
    }
    isa_ok $site->releases->[0]->artwork, ['ArtistSite::Artwork'];
    is $site->releases->[0]->artwork->width, 64,
        'reads artwork width from the image file';
    is $site->releases->[0]->artwork->height, 64,
        'reads artwork height from the image file';
    is $site->artist->hero_image_width, 64,
        'reads hero width from the image file';
    is $site->artist->hero_image_alt, 'Picture of Example Artist',
        'synthesizes hero image alt text';
    is $site->artist->social_links_label, 'Follow Example Artist',
        'synthesizes the social links label';
    is $site->artist->about_title,
        'Songs made for imaginary listeners.',
        'loads the artist-specific about heading';
    is $site->releases->[0]->artwork->alt,
        'Artwork for Signals in the Static by Example Artist',
        'synthesizes release artwork alt text';
    is $site->song_by_slug('blue-hour')->artwork->alt,
        'Artwork for Blue Hour by Example Artist',
        'synthesizes song artwork alt text';
    is $site->song_by_slug('first-light')->effective_artwork->alt,
        'Example Artist playing "First Light" to a festival crowd',
        'preserves explicit alt text';
    isa_ok $site->releases->[0]->links, ['ArtistSite::StreamingLinks'];
    isa_ok $site->releases->[0]->tracks->[0], ['ArtistSite::Track'];
    is refaddr($site->releases->[0]->tracks->[0]->song),
        refaddr($site->song_by_slug('first-light')),
        'track references the shared song object';
    isa_ok $site->song_by_slug('first-light')->lyrics->[0],
        ['ArtistSite::LyricSection'];
    is $site->artist->unannounced_track_label, 'More to come…',
        'loads the artist-level unannounced label';
    is $site->releases->[0]->unannounced_track_label, 'More to come…',
        'release inherits the artist-level label';
    is $site->_unannounced_track_label_for({
        unannounced_track_label => 'Not revealed yet…',
    }), 'Not revealed yet…', 'release label overrides artist label';
    is scalar $site->artist->social_links->@*, 4, 'loads four social links';
    isa_ok $site->artist->social_links->[0], ['ArtistSite::SocialLink'];
    is $site->validation_issues, [], 'current site data passes validation';
};

subtest 'build output' => sub {
    my $home_file = $output_dir->child('index.html');
    my $release_index_file = $output_dir->child('release/index.html');
    my $release_file = $output_dir->child(
        'release/first-light/index.html'
    );
    my $ep_file = $output_dir->child('release/four-sides/index.html');
    my $album_file = $output_dir->child(
        'release/signals-in-the-static/index.html'
    );
    my $song_file = $output_dir->child('song/first-light/index.html');

    ok $home_file->exists, 'builds the home page';
    ok $release_index_file->exists, 'builds the release index';
    ok $release_file->exists, 'builds the release page';
    ok $ep_file->exists, 'builds the EP page';
    ok $album_file->exists, 'builds the album page';
    ok $song_file->exists, 'builds the song page';
    ok $output_dir->child('assets/css/site.css')->exists,
        'copies nested CSS assets';
    ok $output_dir->child('assets/images/artist.webp')->exists,
        'copies nested artist images';
    my $album_og_file = $output_dir->child(
        'assets/og/release-signals-in-the-static.png'
    );
    my $song_og_file = $output_dir->child(
        'assets/og/song-first-light.png'
    );
    ok $output_dir->child('assets/og/home.png')->exists,
        'generates a homepage social image';
    ok $album_og_file->exists, 'generates a release social image';
    ok $song_og_file->exists, 'generates a song social image';
    is [imgsize($album_og_file->stringify)], [1200, 630, 'PNG'],
        'uses the standard landscape social-image dimensions';
    is $site->_blurfill_source_file('artist.webp')->basename,
        'artist.png', 'uses a PNG master when BlurFill cannot read WebP';
    ok $output_dir->child('sitemap.xml')->exists, 'writes a sitemap';
    ok $output_dir->child('robots.txt')->exists, 'writes robots.txt';

    my $release_html = $release_file->slurp_utf8;
    my $ep_html = $ep_file->slurp_utf8;
    my $album_html = $album_file->slurp_utf8;
    my $release_index_html = $release_index_file->slurp_utf8;
    my $song_html = $song_file->slurp_utf8;
    my $home_html = $home_file->slurp_utf8;

    like $home_html, qr{src="/assets/images/artist\.webp"},
        'renders the square homepage hero image';
    like $home_html, qr{alt="Picture of Example Artist"},
        'renders synthesized hero alt text';
    like $home_html,
        qr{<meta content="https://artist\.example/assets/og/home\.png" property="og:image">},
        'homepage metadata uses its generated social image';
    like $home_html, qr{Album\s*·\s*Forthcoming},
        'homepage features the forthcoming album release';
    unlike $home_html, qr{Single\s*·\s*2026-07-26},
        'homepage contains only the featured release';
    like $home_html, qr{href="/release/"},
        'homepage links to the full release index';
    like $release_index_html, qr{Signals in the Static},
        'release index includes the album';
    like $release_index_html, qr{First Light},
        'release index includes the single';
    like $release_index_html, qr{Four Sides},
        'release index includes the EP';
    like $release_index_html, qr{
        Signals\ in\ the\ Static
        .*First\ Light
        .*Four\ Sides
    }sx, 'release index uses release date order';
    like $home_html, qr{href="https://www\.instagram\.com/exampleartist/"},
        'renders the Instagram link';
    like $home_html, qr{title="Instagram"},
        'uses the social service name as a title';
    like $home_html, qr{fa-brands fa-instagram},
        'renders a Font Awesome Instagram icon';
    like $home_html, qr{class="site-footer"},
        'renders the social footer';
    is scalar(() = $home_html =~ /fa-brands fa-instagram/g), 2,
        'renders Instagram in the hero and footer';
    like $home_html, qr{href="https://www\.tiktok\.com/\@exampleartist"},
        'renders the TikTok link';
    like $home_html, qr{googletagmanager\.com/gtag/js\?id=G-TEST123456},
        'renders the configured GA4 measurement ID';

    like $release_html, qr{MusicRecording}, 'includes release JSON-LD';
    like $release_html, qr{social-links--footer},
        'renders social links in the release footer';
    like $release_html,
        qr{<img\s+class="artwork"\s+src="/assets/images/first-light\.webp"},
        'renders the release artwork';
    like $release_html,
        qr{<meta content="https://artist\.example/assets/og/release-first-light\.png" property="og:image">},
        'uses generated release artwork in Open Graph metadata';
    like $release_html,
        qr{<link href="https://artist\.example/release/first-light/" rel="canonical">},
        'includes the canonical URL';
    unlike $release_html, qr{<h2>Lyrics</h2>},
        'keeps lyrics on the song page';
    like $release_html, qr{href="/song/first-light/"},
        'single release links to its song page';

    like $album_html, qr{<title>Signals in the Static — Example Artist</title>},
        'renders the album title';
    like $album_html, qr{"\@type"\s*:\s*"MusicAlbum"},
        'uses album structured data';
    like $album_html, qr{First Light},
        'renders the announced track';
    like $album_html, qr{href="/song/first-light/"},
        'announced album track links to its song page';
    is scalar(() = $album_html =~ /More to come…/g), 11,
        'renders eleven unannounced track slots';
    unlike $album_html, qr{<h2>Lyrics</h2>},
        'does not duplicate song lyrics on the album page';

    like $ep_html, qr{EP\s*·\s*2025-09-04},
        'EP page renders its type and release date';
    like $ep_html, qr{href="/song/blue-hour/"},
        'EP page links to its song pages';

    like $song_html, qr{<h2>Lyrics</h2>}, 'song page renders lyrics';
    like $song_html,
        qr{https://open\.spotify\.com/embed/track/4uLU6hMCjMI75M1A2tKUQC},
        'song page embeds its Spotify track';
    like $song_html,
        qr{<img\s+class="artwork"\s+src="/assets/images/first-light\.webp"},
        'song page falls back to release artwork';
    like $song_html,
        qr{<meta content="https://artist\.example/assets/og/song-first-light\.png" property="og:image">},
        'song page uses generated artwork in social metadata';
    like $song_html,
        qr{"image"\s*:\s*"https://artist\.example/assets/images/first-light\.webp"},
        'song JSON-LD retains the original square artwork';
    like $song_html,
        qr{href="https://soundcloud\.com/exampleartist/first-light"},
        'song page includes its SoundCloud link';
    like $song_html, qr{Signals in the Static},
        'song page links to the album appearance';
    like $song_html, qr{href="/release/first-light/"},
        'song page links to the single appearance';
    like $song_html, qr{"\@type"\s*:\s*"MusicComposition"},
        'song page uses song structured data';
};

subtest 'sitemap and robots content' => sub {
    my $sitemap = $output_dir->child('sitemap.xml')->slurp_utf8;
    my $robots = $output_dir->child('robots.txt')->slurp_utf8;

    like $sitemap, qr{https://artist\.example/</loc>},
        'sitemap includes the home page';
    like $sitemap, qr{https://artist\.example/release/</loc>},
        'sitemap includes the release index';
    like $sitemap, qr{https://artist\.example/release/first-light/},
        'sitemap includes the release';
    like $sitemap, qr{https://artist\.example/release/four-sides/},
        'sitemap includes the EP';
    like $sitemap,
        qr{https://artist\.example/release/signals-in-the-static/},
        'sitemap includes the album';
    like $sitemap, qr{https://artist\.example/song/first-light/},
        'sitemap includes the song';
    like $robots, qr{Sitemap: https://artist\.example/sitemap\.xml},
        'robots.txt points to the sitemap';
};

done_testing;

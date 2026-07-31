use v5.26;
use warnings;

use Test2::V0;
use FindBin;
use lib "$FindBin::Bin/../lib";

use Path::Tiny qw(path);
use Template;

use ArtistSite::Artist;
use ArtistSite::Page;

my $artist = ArtistSite::Artist->new(
    name               => 'Test Artist',
    tagline            => 'A tagline',
    description        => 'Artist description',
    site_url           => 'https://example.com',
    ga4_measurement_id => 'G-TEST1234',
);

my $page = ArtistSite::Page->new(
    artist      => $artist,
    url         => '/',
    title       => 'Test Artist',
    template    => 'index.tt',
    description => 'Page description',
);

my $template_dir = path($FindBin::Bin)->parent->child('templates');
my $template = Template->new({
    INCLUDE_PATH => $template_dir->stringify,
    ENCODING     => 'utf8',
});

my $html = '';
$template->process(
    'layout.tt',
    {
        artist  => $artist,
        page    => $page,
        content => '<p>Page content</p>',
    },
    \$html,
) or die $template->error;

like $html,
    qr{googletagmanager\.com/gtag/js\?id=G-TEST1234},
    'loads gtag.js with the configured measurement ID';
like $html,
    qr{font-awesome/7\.3\.0/css/all\.min\.css},
    'loads the pinned Font Awesome stylesheet';
like $html,
    qr{gtag\('config', 'G-TEST1234'\)},
    'configures GA4 with the measurement ID';

my $artist_without_ga4 = ArtistSite::Artist->new(
    name        => 'Test Artist',
    tagline     => 'A tagline',
    description => 'Artist description',
    site_url    => 'https://example.com',
);

is $artist_without_ga4->about_title, 'A tagline',
    'uses the artist tagline as the default about heading';
is $artist_without_ga4->social_links_label, 'Follow Test Artist',
    'builds a generic social links label from the artist name';

my $page_without_ga4 = ArtistSite::Page->new(
    artist      => $artist_without_ga4,
    url         => '/',
    title       => 'Test Artist',
    template    => 'index.tt',
    description => 'Page description',
);

my $html_without_ga4 = '';
$template->process(
    'layout.tt',
    {
        artist  => $artist_without_ga4,
        page    => $page_without_ga4,
        content => '<p>Page content</p>',
    },
    \$html_without_ga4,
) or die $template->error;

unlike $html_without_ga4, qr{googletagmanager},
    'omits GA4 when no measurement ID is configured';

done_testing;

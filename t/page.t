use v5.26;
use warnings;
use utf8;

use Test2::V0;
use FindBin;
use lib "$FindBin::Bin/../lib";

use ArtistSite::Artist;
use ArtistSite::Page;

my $artist = ArtistSite::Artist->new(
    name        => 'Test Artist',
    tagline     => 'A tagline',
    description => 'Artist description',
    site_url    => 'https://example.com',
);

sub make_page {
    return ArtistSite::Page->new(
        artist      => $artist,
        url         => $_[0],
        title       => $_[1],
        template    => 'page.tt',
        description => 'Page description',
    );
}

subtest 'home page paths and titles' => sub {
    my $page = make_page('/', 'Test Artist');

    is $page->canonical_url, 'https://example.com/', 'canonical URL';
    is $page->output_path, 'index.html', 'output path';
    is $page->page_title, 'Test Artist', 'page title';
};

subtest 'nested page paths and titles' => sub {
    my $page = make_page('/song/a-song/', 'A Song');

    is $page->canonical_url, 'https://example.com/song/a-song/',
        'canonical URL';
    is $page->output_path, 'song/a-song/index.html', 'output path';
    is $page->page_title, 'A Song — Test Artist', 'page title';
};

subtest 'SEO and JSON-LD' => sub {
    my $page = make_page('/song/a-song/', 'A Song');
    my $json_ld = $page->json_ld_data;

    like $page->seo_tags, qr{<title>A Song — Test Artist</title>},
        'SEO tags include the page title';
    like $page->seo_tags, qr{name="twitter:card"},
        'SEO tags include a Twitter card';
    is $json_ld->{'@type'}, 'WebPage', 'JSON-LD type';
    is $json_ld->{url}, 'https://example.com/song/a-song/',
        'JSON-LD canonical URL';
};

done_testing;

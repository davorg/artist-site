use v5.26;
use warnings;

use Test2::V0;
use FindBin;
use lib "$FindBin::Bin/../lib";

use ArtistSite::Artist;
use ArtistSite::Song;
use ArtistSite::Validator;

{
    package TestSite;

    use Moo;

    has artist   => (is => 'ro', required => 1);
    has songs    => (is => 'ro', required => 1);
    has releases => (is => 'ro', required => 1);
}

my $artist = ArtistSite::Artist->new(
    name        => 'Test Artist',
    tagline     => 'A tagline',
    description => 'Artist description',
    site_url    => 'https://example.com',
);

sub incomplete_song {
    return ArtistSite::Song->new(
        artist      => $artist,
        url         => '/song/a-song/',
        template    => 'song.tt',
        slug        => 'a-song',
        title       => 'A Song',
        description => '',
        lyrics      => [],
    );
}

my $site = TestSite->new(
    artist   => $artist,
    songs    => [incomplete_song(), incomplete_song()],
    releases => [],
);
my $issues = ArtistSite::Validator->new(site => $site)->validate;
my %codes = map { $_->code => $_ } $issues->@*;

ok $codes{'duplicate-song-slug'}->is_error,
    'duplicate slugs are structural errors';
is $codes{'song-without-lyrics'}->severity, 'warning',
    'missing lyrics produce a warning';
ok exists $codes{'song-without-artwork'}, 'warns about missing artwork';
ok exists $codes{'song-without-links'}, 'warns about missing links';
ok exists $codes{'song-without-description'},
    'warns about missing SEO descriptions';

done_testing;

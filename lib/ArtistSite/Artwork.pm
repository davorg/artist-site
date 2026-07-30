package ArtistSite::Artwork;

use v5.26;
use warnings;

use Moo;

has file => (
    is       => 'ro',
    required => 1,
);

has alt => (
    is       => 'ro',
    required => 1,
);

has width => (
    is       => 'ro',
    required => 1,
);

has height => (
    is       => 'ro',
    required => 1,
);

1;

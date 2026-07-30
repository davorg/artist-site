package ArtistSite::StorySection;

use v5.26;
use warnings;

use Moo;

has title => (
    is       => 'ro',
    required => 1,
);

has paragraphs => (
    is       => 'ro',
    required => 1,
);

1;

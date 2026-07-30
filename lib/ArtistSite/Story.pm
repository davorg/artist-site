package ArtistSite::Story;

use v5.26;
use warnings;

use Moo;

has intro => (
    is       => 'ro',
    required => 1,
);

has sections => (
    is      => 'ro',
    default => sub { [] },
);

1;

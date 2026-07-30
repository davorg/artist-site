package ArtistSite::Page;

use v5.26;
use warnings;
use utf8;

use Moo;

with 'MooX::Role::SEOTags';
with 'MooX::Role::JSON_LD';

has artist => (
    is       => 'ro',
    required => 1,
);

has url => (
    is       => 'ro',
    required => 1,
);

has title => (
    is       => 'ro',
    required => 1,
);

has template => (
    is       => 'ro',
    required => 1,
);

has description => (
    is       => 'ro',
    required => 1,
);

has image => (
    is => 'ro',
);

has image_alt => (
    is => 'ro',
);

has social_image => (
    is => 'ro',
);

sub canonical_url {
    my ($self) = @_;

    return $self->artist->url_for($self->url);
}

sub output_path {
    my ($self) = @_;

    return 'index.html' if $self->url eq '/';
    return substr($self->url, 1) . 'index.html';
}

sub page_title {
    my ($self) = @_;

    return $self->title if $self->url eq '/';
    return $self->title . ' — ' . $self->artist->name;
}

sub seo_tags {
    my ($self) = @_;

    return $self->tags;
}

sub og_title       { return $_[0]->page_title }
sub og_type        { return 'website' }
sub og_description { return $_[0]->description }
sub og_url         { return $_[0]->canonical_url }
sub og_site_name   { return $_[0]->artist->name }
sub og_image_alt   { return $_[0]->image_alt }

sub og_image {
    my ($self) = @_;

    my $image = $self->social_image // $self->image;

    return unless defined $image;
    return $self->artist->url_for($image);
}

sub json_ld_type {
    return 'WebPage';
}

sub json_ld_fields {
    return [
        {name        => 'page_title'},
        {url         => 'canonical_url'},
        {description => 'description'},
    ];
}

1;

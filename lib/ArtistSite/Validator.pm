package ArtistSite::Validator;

use v5.26;
use warnings;

use Moo;

use ArtistSite::ValidationIssue;

has site => (
    is       => 'ro',
    required => 1,
);

sub validate {
    my ($self) = @_;
    my @issues;

    push @issues, $self->_duplicate_slug_issues;
    push @issues, $self->_featured_release_issues;
    push @issues, $self->_release_issues;
    push @issues, $self->_song_issues;
    push @issues, $self->_artist_issues;

    return \@issues;
}

sub _duplicate_slug_issues {
    my ($self) = @_;
    my @issues;

    push @issues, $self->_duplicates_for('song', $self->site->songs);
    push @issues, $self->_duplicates_for('release', $self->site->releases);

    return @issues;
}

sub _duplicates_for {
    my ($self, $type, $objects) = @_;
    my %count;

    $count{$_->slug}++ for $objects->@*;

    return map {
        $self->_issue(
            error => "duplicate-$type-slug",
            "Duplicate $type slug '$_'",
        )
    } sort grep { $count{$_} > 1 } keys %count;
}

sub _featured_release_issues {
    my ($self) = @_;
    my @featured = grep { $_->featured } $self->site->releases->@*;

    return unless @featured > 1;

    return $self->_issue(
        error => 'multiple-featured-releases',
        'Only one release can be featured on the homepage',
    );
}

sub _release_issues {
    my ($self) = @_;
    my @issues;

    for my $release ($self->site->releases->@*) {
        push @issues, $self->_issue(
            error => 'release-without-tracks',
            "Release '" . $release->title . "' has no tracks",
        ) unless $release->tracks->@*;

        my %positions;
        $positions{$_->position}++ for $release->tracks->@*;
        push @issues, map {
            $self->_issue(
                error => 'duplicate-track-position',
                "Release '" . $release->title
                    . "' uses track position $_ more than once",
            )
        } sort { $a <=> $b }
            grep { $positions{$_} > 1 } keys %positions;

        push @issues, $self->_issue(
            warning => 'released-release-without-streaming',
            "Released release '" . $release->title
                . "' has no streaming services",
        ) if defined $release->release_date
            && !$release->streaming->items->@*;

        push @issues, $self->_issue(
            warning => 'release-without-description',
            "Release '" . $release->title . "' has no SEO description",
        ) unless length $release->description;
    }

    return @issues;
}

sub _song_issues {
    my ($self) = @_;
    my @issues;

    for my $song ($self->site->songs->@*) {
        push @issues, $self->_issue(
            warning => 'song-without-lyrics',
            "Song '" . $song->title . "' has no lyrics",
        ) unless $song->lyrics->@*;

        push @issues, $self->_issue(
            warning => 'song-without-artwork',
            "Song '" . $song->title . "' has no artwork or release artwork",
        ) unless $song->has_artwork;

        push @issues, $self->_issue(
            warning => 'song-without-streaming',
            "Song '" . $song->title . "' has no streaming services",
        ) unless $song->streaming_links->@*;

        push @issues, $self->_issue(
            warning => 'song-without-description',
            "Song '" . $song->title . "' has no SEO description",
        ) unless length $song->description;
    }

    return @issues;
}

sub _artist_issues {
    my ($self) = @_;
    my $artist = $self->site->artist;

    return unless defined $artist->hero_image
        && (!defined $artist->hero_image_alt
            || !length $artist->hero_image_alt);

    return $self->_issue(
        warning => 'hero-image-without-alt',
        'The artist hero image has no alt text',
    );
}

sub _issue {
    my ($self, $severity, $code, $message) = @_;

    return ArtistSite::ValidationIssue->new(
        severity => $severity,
        code     => $code,
        message  => $message,
    );
}

1;

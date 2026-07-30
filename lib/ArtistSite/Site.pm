package ArtistSite::Site;

use v5.26;
use warnings;

use Moo;
use App::BlurFill;
use Image::Size qw(imgsize);
use Template;
use YAML::XS qw(LoadFile);

use ArtistSite::Artist;
use ArtistSite::Artwork;
use ArtistSite::LyricSection;
use ArtistSite::Page;
use ArtistSite::Release;
use ArtistSite::SocialLink;
use ArtistSite::Song;
use ArtistSite::StreamingLinks;
use ArtistSite::Story;
use ArtistSite::StorySection;
use ArtistSite::Track;
use ArtistSite::Validator;

has data_dir   => (is => 'ro', required => 1);
has output_dir => (is => 'ro', required => 1);
has theme_dir  => (is => 'ro', required => 1);
has assets_dir => (is => 'ro', required => 1);

has artist   => (is => 'lazy');
has songs    => (is => 'lazy');
has releases => (is => 'lazy');
has pages    => (is => 'lazy');
has validation_issues => (is => 'lazy');

sub _build_artist {
    my ($self) = @_;
    my $artist_data = LoadFile($self->data_dir->child('artist.yml'));
    my $social_link_data = delete $artist_data->{social_links} // [];

    my $social_links = [
        map { ArtistSite::SocialLink->new($_) } $social_link_data->@*
    ];

    if (defined $artist_data->{hero_image}) {
        my ($width, $height) = $self->_image_dimensions(
            $artist_data->{hero_image}
        );
        $artist_data->{hero_image_width} = $width;
        $artist_data->{hero_image_height} = $height;
    }

    return ArtistSite::Artist->new(
        $artist_data->%*,
        social_links => $social_links,
    );
}

sub _build_releases {
    my ($self) = @_;
    my $release_data = LoadFile($self->data_dir->child('releases.yml'));

    my $releases = [
        sort { $self->_compare_releases($a, $b) }
        map { $self->_release_from_data($_) } $release_data->@*
    ];

    for my $release ($releases->@*) {
        for my $track ($release->tracks->@*) {
            $track->song->add_release($release)
                if defined $track->song;
        }
    }

    return $releases;
}

sub _compare_releases {
    my ($self, $left, $right) = @_;

    my $left_is_released = defined $left->release_date;
    my $right_is_released = defined $right->release_date;

    return $left_is_released <=> $right_is_released
        if $left_is_released != $right_is_released;

    return $left->title cmp $right->title
        unless $left_is_released;

    return $right->release_date cmp $left->release_date
        || $left->title cmp $right->title;
}

sub _build_songs {
    my ($self) = @_;
    my $song_data = LoadFile($self->data_dir->child('songs.yml'));

    return [map { $self->_song_from_data($_) } $song_data->@*];
}

sub _song_from_data {
    my ($self, $song_data) = @_;

    my $lyrics = [
        map { ArtistSite::LyricSection->new($_) } $song_data->{lyrics}->@*
    ];

    my %song_attributes = $song_data->%*;
    delete @song_attributes{qw(artwork links story)};

    $song_attributes{artwork} = $self->_artwork_from_data(
        $song_data->{artwork},
        'Artwork for ' . $song_data->{title} . ' by ' . $self->artist->name,
    ) if exists $song_data->{artwork};

    $song_attributes{links} = ArtistSite::StreamingLinks->new(
        $song_data->{links}
    ) if exists $song_data->{links};

    $song_attributes{story} = $self->_story_from_data(
        $song_data->{story}
    ) if exists $song_data->{story};

    return ArtistSite::Song->new(
        %song_attributes,
        artist   => $self->artist,
        url      => '/song/' . $song_data->{slug} . '/',
        template => 'song.tt',
        social_image => '/assets/og/song-' . $song_data->{slug} . '.png',
        lyrics   => $lyrics,
    );
}

sub _story_from_data {
    my ($self, $story_data) = @_;
    my $sections = [
        map { ArtistSite::StorySection->new($_) }
            ($story_data->{sections} // [])->@*
    ];

    return ArtistSite::Story->new(
        intro    => $story_data->{intro},
        sections => $sections,
    );
}

sub song_by_slug {
    my ($self, $slug) = @_;

    for my $song ($self->songs->@*) {
        return $song if $song->slug eq $slug;
    }

    die "Release references unknown song '$slug'";
}

sub _release_from_data {
    my ($self, $release_data) = @_;

    my $unannounced_label = $self->_unannounced_track_label_for($release_data);

    my $tracks = [
        map { $self->_track_from_data($_, $unannounced_label) }
            $release_data->{tracks}->@*
    ];

    my %release_attributes = $release_data->%*;
    delete $release_attributes{tracks};

    my $artwork = $self->_artwork_from_data(
        $release_data->{artwork},
        'Artwork for ' . $release_data->{title}
            . ' by ' . $self->artist->name,
    );

    return ArtistSite::Release->new(
        %release_attributes,
        artist    => $self->artist,
        url       => '/release/' . $release_data->{slug} . '/',
        template  => 'release.tt',
        image     => '/assets/images/' . $release_data->{artwork}{file},
        image_alt => $artwork->alt,
        social_image => '/assets/og/release-'
            . $release_data->{slug} . '.png',
        artwork   => $artwork,
        links     => ArtistSite::StreamingLinks->new($release_data->{links}),
        tracks    => $tracks,
        unannounced_track_label => $unannounced_label,
    );
}

sub _unannounced_track_label_for {
    my ($self, $release_data) = @_;

    return $release_data->{unannounced_track_label}
        // $self->artist->unannounced_track_label;
}

sub _track_from_data {
    my ($self, $track_data, $unannounced_label) = @_;

    my %track_attributes = (
        position          => $track_data->{position},
        unannounced_label => $unannounced_label,
    );

    $track_attributes{status} = $track_data->{status}
        if exists $track_data->{status};

    $track_attributes{song} = $self->song_by_slug($track_data->{song})
        if exists $track_data->{song};

    return ArtistSite::Track->new(%track_attributes);
}

sub _artwork_from_data {
    my ($self, $artwork_data, $default_alt) = @_;
    my %artwork_attributes = $artwork_data->%*;
    my ($width, $height) = $self->_image_dimensions(
        $artwork_attributes{file}
    );

    delete @artwork_attributes{qw(width height)};
    $artwork_attributes{alt} //= $default_alt;

    return ArtistSite::Artwork->new(
        %artwork_attributes,
        width  => $width,
        height => $height,
    );
}

sub _image_dimensions {
    my ($self, $filename) = @_;
    my $image_file = $self->_source_image_file($filename);
    my ($width, $height) = imgsize($image_file->stringify);

    die "Could not read image dimensions from '$image_file'"
        unless defined $width && defined $height;

    return ($width, $height);
}

sub _build_pages {
    my ($self) = @_;

    my $home_page = ArtistSite::Page->new(
        artist      => $self->artist,
        url         => '/',
        title       => $self->artist->name,
        template    => 'index.tt',
        description => $self->artist->description,
        image       => $self->artist->hero_image_url,
        image_alt   => $self->artist->hero_image_alt,
        social_image => '/assets/og/home.png',
    );

    my $featured_release = $self->featured_release;

    my $release_index = ArtistSite::Page->new(
        artist      => $self->artist,
        url         => '/release/',
        title       => 'Releases',
        template    => 'release-index.tt',
        description => 'Singles, EPs and albums by ' . $self->artist->name,
        image       => $featured_release->image,
        image_alt   => $featured_release->image_alt,
        social_image => $featured_release->social_image,
    );

    return [
        $home_page,
        $release_index,
        $self->releases->@*,
        $self->songs->@*,
    ];
}

sub featured_release {
    my ($self) = @_;

    for my $release ($self->releases->@*) {
        return $release if $release->featured;
    }

    return $self->releases->[0];
}

sub build {
    my ($self) = @_;

    $self->_report_validation_issues;
    $self->output_dir->mkpath;

    my $template = Template->new({
        INCLUDE_PATH => $self->theme_dir->stringify,
        ENCODING     => 'utf8',
    });

    $self->_copy_assets;
    $self->_generate_social_images;
    $self->_render_page($template, $_) for $self->pages->@*;
    $self->_write_sitemap;
    $self->_write_robots;

    return $self;
}

sub _generate_social_images {
    my ($self) = @_;
    my $social_image_dir = $self->output_dir->child('assets/og');

    $social_image_dir->mkpath;

    $self->_generate_social_image(
        $self->artist->hero_image,
        $social_image_dir->child('home.png'),
    ) if defined $self->artist->hero_image;

    for my $release ($self->releases->@*) {
        $self->_generate_social_image(
            $release->artwork->file,
            $social_image_dir->child('release-' . $release->slug . '.png'),
        );
    }

    for my $song ($self->songs->@*) {
        next unless $song->has_artwork;

        $self->_generate_social_image(
            $song->effective_artwork->file,
            $social_image_dir->child('song-' . $song->slug . '.png'),
        );
    }

    return;
}

sub _generate_social_image {
    my ($self, $source_filename, $output_file) = @_;
    my $source_file = $self->_blurfill_source_file($source_filename);

    App::BlurFill->new(
        file   => $source_file->stringify,
        width  => 1200,
        height => 630,
        output => $output_file->stringify,
    )->process;

    return;
}

sub _blurfill_source_file {
    my ($self, $source_filename) = @_;
    my $source_file = $self->_source_image_file($source_filename);

    return $source_file unless $source_filename =~ /\.webp\z/i;

    my $png_filename = $source_filename;
    $png_filename =~ s/\.webp\z/.png/i;
    my $png_file = $self->_source_image_file($png_filename);

    return $png_file if $png_file->exists;

    die "BlurFill cannot read '$source_file' because this Imager "
        . "installation has no WebP support. Add '$png_file' as a "
        . "build-time source image.\n";
}

sub _source_image_file {
    my ($self, $filename) = @_;

    return $self->assets_dir->child('images', $filename);
}

sub _build_validation_issues {
    my ($self) = @_;

    return ArtistSite::Validator->new(site => $self)->validate;
}

sub _report_validation_issues {
    my ($self) = @_;
    my @errors = grep { $_->is_error } $self->validation_issues->@*;

    die join("\n", map { $_->as_string } @errors) . "\n"
        if @errors;

    for my $issue ($self->validation_issues->@*) {
        warn $issue->as_string . "\n";
    }

    return;
}

sub _render_page {
    my ($self, $template, $page) = @_;

    my $body = '';
    $template->process(
        $page->template,
        {
            artist   => $self->artist,
            page     => $page,
            releases => $self->releases,
            featured_release => $self->featured_release,
        },
        \$body,
    ) or die $template->error;

    my $html = '';
    $template->process(
        'layout.tt',
        {
            artist  => $self->artist,
            page    => $page,
            content => $body,
        },
        \$html,
    ) or die $template->error;

    my $output_file = $self->output_dir->child($page->output_path);
    $output_file->parent->mkpath;
    $output_file->spew_utf8($html);

    return;
}

sub _copy_assets {
    my ($self) = @_;
    my $output_assets = $self->output_dir->child('assets');

    $output_assets->remove_tree({safe => 0}) if $output_assets->exists;
    $output_assets->mkpath;

    for my $asset ($self->assets_dir->children) {
        $self->_copy_asset_tree(
            $asset,
            $output_assets->child($asset->basename),
        );
    }

    return;
}

sub _copy_asset_tree {
    my ($self, $source, $destination) = @_;

    if ($source->is_dir) {
        $destination->mkpath;
        for my $child ($source->children) {
            $self->_copy_asset_tree(
                $child,
                $destination->child($child->basename),
            );
        }
        return;
    }

    $source->copy($destination);

    return;
}

sub _write_sitemap {
    my ($self) = @_;

    my $url_entries = join '', map {
        '  <url><loc>' . $_->canonical_url . "</loc></url>\n"
    } $self->pages->@*;

    my $sitemap = qq{<?xml version="1.0" encoding="UTF-8"?>\n};
    $sitemap .= qq{<urlset xmlns="http://www.sitemaps.org/schemas/sitemap/0.9">\n};
    $sitemap .= $url_entries;
    $sitemap .= "</urlset>\n";

    $self->output_dir->child('sitemap.xml')->spew_utf8($sitemap);

    return;
}

sub _write_robots {
    my ($self) = @_;

    my $robots = "User-agent: *\n";
    $robots .= "Allow: /\n";
    $robots .= 'Sitemap: ' . $self->artist->site_url . "/sitemap.xml\n";

    $self->output_dir->child('robots.txt')->spew_utf8($robots);

    return;
}

1;

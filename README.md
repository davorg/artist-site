# Artist Site

A generic Perl/Moo/Template Toolkit static-site engine for artists. Oneirina is its first site.

Run `bin/build-site`; generated files are written to `docs/`.

The build command accepts a separate artist repository:

```console
bin/build-site --site-dir /path/to/artist --output-dir _site
```

The artist repository supplies `data/` and `assets/images/`. The engine
supplies the templates and CSS.

## Docker

Build the engine image:

```console
docker build -t artist-site .
```

Generate a mounted artist site:

```console
docker run --rm \
  --user "$(id -u):$(id -g)" \
  --volume "/path/to/artist:/site" \
  artist-site
```

The container writes the generated site to `/path/to/artist/_site`.

## Publishing the Docker image

Add `DOCKERHUB_USERNAME` and `DOCKERHUB_TOKEN` as repository secrets on
GitHub. To publish a release, update `$ArtistSite::Site::VERSION`, commit the
change, and push a matching tag:

```console
git tag VERSION.0.1.0
git push origin VERSION.0.1.0
```

The workflow publishes `davorg/artist-site` for AMD64 and ARM64, tagged with
the full version (`0.1.0`), the major/minor version (`0.1`), and `latest`.

Music is modelled in three layers:

- Songs own creative content such as titles, descriptions, and lyrics.
- Tracks place songs at an ordered position within a release.
- Releases own publication details such as type, date, artwork, and links.

The homepage features releases. Song content lives in `data/songs.yml`, while
release packaging and track order live in `data/releases.yml`.

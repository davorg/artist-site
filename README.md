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

Music is modelled in three layers:

- Songs own creative content such as titles, descriptions, and lyrics.
- Tracks place songs at an ordered position within a release.
- Releases own publication details such as type, date, artwork, and links.

The homepage features releases. Song content lives in `data/songs.yml`, while
release packaging and track order live in `data/releases.yml`.

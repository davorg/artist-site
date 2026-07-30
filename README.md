# Artist Site

A generic Perl/Moo/Template Toolkit static-site engine for artists. Oneirina is its first site.

Run `bin/build-site`; generated files are written to `docs/`.

Music is modelled in three layers:

- Songs own creative content such as titles, descriptions, and lyrics.
- Tracks place songs at an ordered position within a release.
- Releases own publication details such as type, date, artwork, and links.

The homepage features releases. Song content lives in `data/songs.yml`, while
release packaging and track order live in `data/releases.yml`.

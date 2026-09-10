# Override CSS

Client builds can override the default styling by adding a file at
`assets/css/override.css` in the artist repository.

When that file exists:

- it is copied into the generated site as `/assets/css/override.css`
- it is loaded after `/assets/css/site.css`
- any other non-image files under the artist repository's `assets/` tree are
  also copied, so you can include custom fonts or other supporting files

The engine stylesheet remains the default. `override.css` only needs to contain
the rules you want to change.

## Basic structure

A typical artist repository might contain:

```text
assets/
  css/
    override.css
  fonts/
    headline.woff2
```

## Good first overrides

The main stylesheet already defines a few CSS custom properties at `:root`,
which makes colour changes straightforward:

- `--ink` – the main text colour
- `--muted` – secondary text
- `--night` – the main dark background
- `--acid` – accent colour used for links, buttons, and highlights

For example:

```css
:root {
  --ink: #f8f2e8;
  --muted: #c6b8a5;
  --night: #24130f;
  --acid: #ff8c42;
}
```

Because the base stylesheet uses these variables for much of the site, changing
them will affect:

- the page background
- body text
- accent labels
- buttons
- social icons and hover states
- text links

## Typography

The default stylesheet sets:

- the main sans-serif font on `:root`
- the display serif font on `.wordmark, h1, h2, h3`
- release and lyric serif styling on `.track-listing ol` and `.lyric p`

That means you can swap fonts with rules like:

```css
@font-face {
  font-family: "Headline";
  src: url("/assets/fonts/headline.woff2") format("woff2");
}

:root {
  font-family: "Inter", Arial, sans-serif;
}

.wordmark,
h1,
h2,
h3,
.track-listing ol,
.lyric p {
  font-family: "Headline", Georgia, serif;
}
```

## Common component overrides

Some useful selectors to target are:

- `.button` for call-to-action buttons
- `.text-link` for inline accent links
- `.site-header` and `.site-footer` for chrome around the page
- `.hero`, `.release-card`, and `.release-hero` for main content layout
- `.social-link` and `.social-link__icon` for social buttons
- `.player` and `.player--video` for embedded media

Examples:

```css
.button {
  border-radius: 999px;
}

.site-header {
  border-bottom-color: #ffffff40;
}

.hero__image,
.artwork {
  box-shadow: none;
}
```

## Notes

- Put only overrides in `override.css`; do not copy the whole engine stylesheet.
- Prefer changing the `:root` variables first when adjusting colours.
- If you add custom font files, keep them under the artist repository's
  `assets/` tree so they are copied into the generated site.

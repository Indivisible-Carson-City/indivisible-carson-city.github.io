# Indivisible Carson City — Jekyll Site

## Quick Commands
```bash
eval "$(rbenv init - zsh)" && bundle exec jekyll serve --future   # Local dev server at localhost:4000
eval "$(rbenv init - zsh)" && bundle exec jekyll build             # Build to _site/
```

## Stack
- **Jekyll 4.4** (not github-pages gem)
- **Bootstrap 5.3 via CDN** — no build tools, no node_modules
- **GitHub Pages** via GitHub Actions for deployment
- **Ruby 3.3.6** via rbenv

## Branding
- Indivisible Teal: `#28B5B5` (navbar, footer, primary buttons)
- Indivisible Red: `#BB133E` (accent buttons, CTAs)
- Logo: `assets/images/branding/indivisible_logo.png`
- Headings: Roboto Condensed (Google Fonts)
- Body: system font stack

## Key Files
- `_data/events.yml` — event list (placeholder data, will eventually come from external API)
- `_data/navigation.yml` — nav links
- `assets/css/custom.css` — brand overrides on top of Bootstrap
- `.github/workflows/jekyll.yml` — GitHub Actions deploy workflow

## Pages
- Home (`/`) — hero (photo background), mission, upcoming events, photo gallery
- About (`/about`) — about the group
- Events (`/events`) — full events listing

## Conventions
- `future: true` is set in `_config.yml` so future-dated events render locally
- GitHub Actions workflow builds and deploys on push to `main`

## Do Not
- Commit `.claude/` or `_site/`
- Edit `Gemfile.lock` directly — run `bundle install` instead
- Add node_modules or JS build tools — Bootstrap is CDN-only

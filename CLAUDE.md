# Indivisible Carson City — Jekyll Site

## Quick Commands
```bash
eval "$(rbenv init - zsh)" && bundle exec jekyll serve --future   # Local dev server at localhost:4000
eval "$(rbenv init - zsh)" && bundle exec jekyll build             # Build to _site/
```

## Stack
- **Jekyll 4.4** (not github-pages gem)
- **Tailwind CSS via CDN** — no build tools, no node_modules
- **GitHub Pages** via GitHub Actions for deployment
- **Ruby 3.3.6** via rbenv

## Branding
- Indivisible Navy: `#00417b` (navbar, footer, alert banner, primary buttons) — Tailwind `brand`
- Indivisible Navy Dark: `#002d54` (hover) — Tailwind `brand-dark`
- Indivisible Red: `#BB133E` (accent buttons, CTAs) — Tailwind `accent`
- Logos (do not recolor): `assets/images/branding/indivisible_logo.png`, `assets/images/branding/indivisible_circle_logo_new.png`
- Headings: Roboto Condensed (Google Fonts)
- Body: system font stack

## Key Files
- `assets/js/events.js` — client-side Mobilize API fetch + event card rendering
- `_plugins/substack_feed.rb` — fetches Substack RSS at build time into `site.data.substack_posts`
- `assets/css/custom.css` — brand overrides on top of Tailwind
- `.github/workflows/jekyll.yml` — GitHub Actions deploy workflow (push + daily cron)

## Data Files
- `_data/alert.yml` — homepage alert banner (text, link, expires date)
- `_data/spotlight.yml` — homepage spotlight flyers (images, links, expires date)
- `_data/gallery.yml` — photo gallery entries in reverse chronological order
- `_data/navigation.yml` — nav links

## Pages
- Home (`/`) — alert banner, hero, spotlight, mission, events, photo gallery, CTA
- About (`/about`) — about the group
- Events (`/events`) — full events listing from Mobilize API
- Gallery (`/gallery`) — event photos in reverse chronological order
- Blog (`/blog`) — recent Substack posts
- Donate (`/donate`) — ActBlue donation link

## Conventions
- `future: true` is set in `_config.yml` so future-dated events render locally
- GitHub Actions workflow builds and deploys on push to `main` and daily at 8 AM UTC
- Alert and spotlight sections support `expires: YYYY-MM-DD` — auto-hide after that date on next build
- Gallery entries go at the **top** of `_data/gallery.yml` (newest first)
- Homepage "In Action" section shows only the most recent gallery entry
- Spotlight flyer images go in `assets/images/spotlight/`
- Event photos go in `assets/images/events/`

## Do Not
- Commit `.claude/` or `_site/`
- Edit `Gemfile.lock` directly — run `bundle install` instead
- Add node_modules or JS build tools — Tailwind is CDN-only
- Rely on third-party CORS proxies for client-side fetches — use build-time plugins instead

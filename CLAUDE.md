# Indivisible Carson City — Jekyll Site

## Quick Commands
```bash
eval "$(rbenv init - zsh)" && bundle exec jekyll serve --future   # Local dev server at localhost:4000
eval "$(rbenv init - zsh)" && bundle exec jekyll build             # Build to _site/

bin/preview start   # Share the local site publicly via a Cloudflare quick tunnel (prints the URL)
bin/preview url     # Reprint the current share URL
bin/preview stop    # Tear it down
```
`bin/preview` runs Jekyll + cloudflared in one tmux session (`icc-preview`), so it survives closing
the terminal — but not the laptop sleeping, and the URL changes on every `start`.

## Stack
- **Jekyll 4.4** (not github-pages gem)
- **Tailwind CSS via CDN** — no build tools, no node_modules
- **GitHub Pages** via GitHub Actions for deployment
- **Ruby 3.3.6** via rbenv

## Branding
- Indivisible Navy: `#00417b` (navbar, footer, primary buttons) — Tailwind `brand`
- Indivisible Navy Dark: `#002d54` (hover) — Tailwind `brand-dark`
- Alert Banner: `#1a5c9e` (lighter navy, distinct from navbar)
- Indivisible Red: `#BB133E` (accent buttons, CTAs) — Tailwind `accent`
- Logos (transparent background): `assets/images/branding/indivisible_logo.png`, `assets/images/branding/indivisible_circle_logo_new.png`
- Headings: Roboto Condensed (Google Fonts)
- Body: system font stack

## Key Files
- `assets/js/events.js` — client-side Mobilize API fetch + event card rendering
- `_plugins/substack_feed.rb` — fetches Substack via rss2json.com proxy at build time into `site.data.substack_posts`; caches to `_data/substack_cache.yml` as fallback
- `assets/css/custom.css` — brand overrides on top of Tailwind (hand-rolled `.prose` rules; the Tailwind Typography plugin is NOT loaded, so `prose-*` modifier classes are no-ops)
- `_includes/candidate_comparison.html` — renders a race from `_data/races/*.yml`; cells support `text`, `paragraphs`, or `groups`, plus an optional `stance` chip
- `.github/workflows/jekyll.yml` — GitHub Actions deploy workflow (push + daily cron)

## Data Files
- `_data/alert.yml` — homepage alert banner (text, link, expires date)
- `_data/spotlight.yml` — homepage spotlight flyers (images, links, expires date)
- `_data/gallery.yml` — photo gallery entries in reverse chronological order
- `_data/substack_cache.yml` — cached Substack posts (auto-updated on build, fallback if fetch fails)
- `_data/navigation.yml` — nav links
- `_data/vote.yml` — /vote page: endorsement excerpt, voter resource links, comparison cards (supports `enabled` + `expires`)
- `_data/races/cd2.yml`, `_data/races/governor.yml` — candidate comparison content (background rows + issue positions)

## Pages
- Home (`/`) — alert banner, hero, spotlight, mission, events, photo gallery, CTA
- About (`/about`) — about the group
- Events (`/events`) — full events listing from Mobilize API
- Gallery (`/gallery`) — event photos in reverse chronological order
- Blog (`/blog`) — recent Substack posts (renamed from Newsletter; `/newsletter` redirects here)
- Donate (`/donate`) — ActBlue donation link
- Vote (`/vote`) — 2026 election hub: endorsement panel, voter resources, comparison cards
- `/vote/cd2`, `/vote/governor` — side-by-side candidate comparisons
- `/vote/endorsement` — full text of the CD2 endorsement statement

## Conventions
- `future: true` is set in `_config.yml` so future-dated events render locally
- GitHub Actions workflow builds and deploys on push to `main` and daily at 8 AM UTC
- Alert and spotlight sections support `expires: YYYY-MM-DD` — auto-hide after that date on next build
- Gallery entries go at the **top** of `_data/gallery.yml` (newest first)
- Homepage "In Action" section shows only the most recent gallery entry
- Spotlight flyer images go in `assets/images/spotlight/`
- `/vote` pages use trailing-slash permalinks so each emits its own `index.html` — a bare `/vote` permalink would collide with the `vote/` directory on GitHub Pages
- Candidate comparisons list the Democrat first in both races, and each comparison page ends with a sources/methodology note
- Event photos go in `assets/images/events/`
- Substack feed is fetched via rss2json.com (free proxy) because Cloudflare blocks direct requests from GitHub Actions IPs
- Blog posts update automatically on each daily build — no manual intervention needed

## Planned: Google Sheets Events
- Plugin `_plugins/events_sheet.rb` was built and tested but not yet deployed
- Replaces Mobilize API with a Google Sheet (build-time CSV fetch, grouped by month)
- Blocked until the stakeholder's Google Sheet is shared as "Anyone with the link can view"
- Sheet ID (prototype): `1NU9_vK42int55KCzw7EXP0Urloia-UsifC8QWOGeQJg`
- Sheet ID (real, currently private): `1rWMT6yLwDc8Fx09fkIYvXfk2h0Apb_T4-E8YmGDPG30`
- Expected columns: Start Date, End Date, Event Name, Start Time, End Time, Location, Description, Register Here Hyperlink Text, More Information Hyperlink Text

## Do Not
- Commit `.claude/` or `_site/`
- Edit `Gemfile.lock` directly — run `bundle install` instead
- Add node_modules or JS build tools — Tailwind is CDN-only
- Edit `_data/substack_cache.yml` manually — it's auto-generated by the plugin

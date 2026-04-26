# Indivisible Carson City

Website for Indivisible Carson City — a local grassroots group promoting civic engagement and defending democracy in Carson City, Nevada.

**Live site:** [indivisiblecarsoncity.org](https://indivisiblecarsoncity.org)

## Tech Stack

- [Jekyll 4](https://jekyllrb.com/) — static site generator
- [Tailwind CSS](https://tailwindcss.com/) — utility-first CSS (via CDN)
- [GitHub Pages](https://pages.github.com/) — hosting via GitHub Actions

## Local Development

### Prerequisites

- [rbenv](https://github.com/rbenv/rbenv) with Ruby 3.3.6
- Bundler (`gem install bundler`)

### Setup

```bash
git clone https://github.com/Indivisible-Carson-City/indivisible-carson-city.github.io.git
cd indivisible-carson-city.github.io
rbenv install 3.3.6    # if not already installed
bundle install
```

### Run Locally

```bash
bundle exec jekyll serve --future
```

Open [http://localhost:4000](http://localhost:4000)

## Deploying

The site deploys automatically to GitHub Pages on every push to `main` via GitHub Actions. A daily scheduled rebuild (8 AM UTC) ensures expired alerts and spotlight content are removed on time. The workflow is at `.github/workflows/jekyll.yml`.

## Pages

| Page | Path | Description |
|------|------|-------------|
| Home | `/` | Hero, spotlight, events, photo gallery, CTA |
| About | `/about` | About the group |
| Events | `/events` | Full events listing from Mobilize |
| Gallery | `/gallery` | Event photos in reverse chronological order |
| Newsletter | `/newsletter` | Recent Substack posts (fetched at build time) |
| Donate | `/donate` | Donation page with ActBlue link |

## Content Management

Most content updates are done through YAML data files — no HTML editing required:

| File | Purpose |
|------|---------|
| `_data/alert.yml` | Homepage alert banner (text, link, expiration date) |
| `_data/spotlight.yml` | Homepage spotlight flyers/graphics (images, links, expiration date) |
| `_data/gallery.yml` | Photo gallery (events with photos, credits, videos) |
| `_data/navigation.yml` | Nav bar links |

### Alert Banner & Spotlight

Both support an `expires` date field (YYYY-MM-DD). After that date, the section automatically hides on the next site build. The daily scheduled rebuild ensures this happens without a manual push.

### Adding a New Gallery Event

Add a new entry at the **top** of `_data/gallery.yml`:

```yaml
- title: "Event Name"
  date: 2025-06-01
  photos:
    - image: /assets/images/events/photo.jpg
      alt: "Description"
      credit: "Photographer Name"
```

### Newsletter

The `_plugins/substack_feed.rb` plugin fetches the latest posts from the [Indivisible Carson City Substack](https://indivisiblecarsoncity.substack.com/) RSS feed at build time. No manual updates needed.

## Project Structure

```
├── _config.yml              # Jekyll configuration
├── _layouts/                # Page templates (default, home, page, gallery, newsletter)
├── _includes/               # Reusable components (nav, footer, head)
├── _plugins/
│   └── substack_feed.rb     # Fetches Substack RSS at build time
├── _data/
│   ├── alert.yml            # Homepage alert banner
│   ├── spotlight.yml        # Homepage spotlight section
│   ├── gallery.yml          # Photo gallery data
│   └── navigation.yml       # Nav links
├── assets/
│   ├── css/custom.css       # Brand overrides
│   ├── js/events.js         # Mobilize API event loader
│   └── images/
│       ├── branding/        # Logos
│       ├── events/          # Event photos
│       └── spotlight/       # Spotlight flyers
├── index.md                 # Homepage
├── about.md                 # About page
├── events.html              # Events listing
├── gallery.md               # Gallery page
├── newsletter.md            # Newsletter page
├── donate.md                # Donate page
└── 404.html                 # Custom 404
```

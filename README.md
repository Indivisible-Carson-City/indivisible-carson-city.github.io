# Indivisible Carson City

Website for Indivisible Carson City — a local grassroots group promoting progressive values and civic engagement in Carson City, Nevada.

## Tech Stack

- [Jekyll 4](https://jekyllrb.com/) — static site generator
- [Bootstrap 5](https://getbootstrap.com/) — CSS framework (via CDN)
- [GitHub Pages](https://pages.github.com/) — hosting via GitHub Actions

## Local Development

### Prerequisites

- [rbenv](https://github.com/rbenv/rbenv) with Ruby 3.3.6
- Bundler (`gem install bundler`)

### Setup

```bash
git clone https://github.com/Indivisible-Carson-City/website.git
cd website
rbenv install 3.3.6    # if not already installed
bundle install
```

### Run Locally

```bash
bundle exec jekyll serve --future
```

Open [http://localhost:4000](http://localhost:4000)

## Deploying

The site deploys automatically to GitHub Pages on every push to `main` via GitHub Actions. The workflow is at `.github/workflows/jekyll.yml`.

To set up GitHub Pages:
1. Go to the repo's Settings > Pages
2. Set Source to **GitHub Actions**

## Project Structure

```
├── _config.yml          # Jekyll configuration
├── _layouts/            # Page templates (default, home, page)
├── _includes/           # Reusable components (nav, footer, event-card)
├── _data/
│   ├── events.yml       # Upcoming events
│   └── navigation.yml   # Nav links
├── assets/
│   └── css/custom.css   # Brand overrides
├── index.md             # Homepage
├── about.md             # About page
├── events.html          # Events listing page
└── 404.html             # Custom 404
```

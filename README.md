# arcanedata.us

Static splash page for **Arcane Data LLC**, served via GitHub Pages on the
apex domain `arcanedata.us`.

Theme: **cream "arcane parchment"** — a warm sepia palette wearing the
retro/GeoCities treatment from `kiki-personal-vault` (sharp 1px borders, hard
no-blur offset shadows, Helvetica Neue, deco rows).

## Files
- `index.html` — the splash page
- `styles.css` — theme + layout
- `favicon.svg` — keyhole brand mark
- `404.html` — themed not-found page
- `CNAME` — tells GitHub Pages to serve `arcanedata.us`

## Edit the content
- **Tagline**: the line under the title in `index.html` (`<p class="card__tagline">`).
- **Email**: the `mailto:` link in `index.html`.
- **Colors**: the `:root` custom properties at the top of `styles.css`.

## Local preview
Just open `index.html` in a browser, or:
```bash
python3 -m http.server 8000
# visit http://localhost:8000
```

## Deploy
Pushing to `main` auto-publishes via GitHub Pages
(Settings → Pages → Source: `main` / root).

## DNS (Namecheap → Advanced DNS)
Point the domain at GitHub Pages:

**A records** (Host `@`) → GitHub Pages IPs:
```
185.199.108.153
185.199.109.153
185.199.110.153
185.199.111.153
```

**CNAME record** (Host `www`) → `meinsta.github.io.`

Remove Namecheap's default parking / "URL Redirect" records first. After DNS
propagates, enable **Enforce HTTPS** in Settings → Pages.

# Bundled fonts

## Arimo
- `arimo-400.woff2` (regular), `arimo-700.woff2` (bold) — Latin subset.
- **Arimo** is a libre, metrically-compatible equivalent of Helvetica/Arial,
  so the site renders with Helvetica metrics even on machines without
  Helvetica installed (Windows, Linux).
- License: **Apache License 2.0**. Source: https://github.com/google/fonts/tree/main/apache/arimo
- Files fetched via Fontsource: https://www.npmjs.com/package/@fontsource/arimo

The CSS font stack keeps genuine Helvetica first
(`"Helvetica Neue", Helvetica, "Arimo", Arial, sans-serif`), so Macs use real
Helvetica and everyone else falls back to the bundled Arimo.

Note: real Helvetica / Helvetica Neue are proprietary and cannot be
redistributed here, which is why Arimo is bundled instead.

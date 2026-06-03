# Changelog

All notable changes to CSV Quick Look are documented here.
Format follows [Keep a Changelog](https://keepachangelog.com/en/1.1.0/).

## [1.0.2] – 2026-06-03

### Fixed
- Settings (max rows, auto-detect delimiter) now correctly apply to previews — the app and extension were using separate UserDefaults sandboxes; they now share an App Group container
- Truncation notice ("Showing first N of M rows") now appears when a file is capped at the row limit
- Slow trackpad scrolling no longer freezes visible rows mid-scroll
- Delimiter detection no longer misidentifies the delimiter when candidate characters appear inside quoted fields
- `escapeHtml` now escapes single quotes, making it correct by definition
- Row limit was off by one (stored one extra row at the limit)
- Distributed binaries are now built with Hardened Runtime enabled, removing a Gatekeeper block for Homebrew users

### Added
- CI workflow: every push and pull request to `main` now runs a build check
- SECURITY.md with a vulnerability reporting policy

## [1.0.1] – 2026-06-02

### Added
- GitHub Actions release workflow: builds a signed binary and uploads it to each GitHub release automatically
- Homebrew tap (`brew install --cask adamorad/tap/csv-quick-look`)
- TSV file support (`public.tab-separated-values` UTI)

### Fixed
- `autoDetectDelimiter` setting was stored in UserDefaults but never read by the extension — now correctly wired to the parser

## [1.0.0] – 2026-06-01

Initial release.

- QuickLook preview for `.csv` and `.tsv` files
- Virtual scroll (handles 500k+ row files)
- Click-to-sort columns (numeric-aware)
- Live row filter with Escape to clear
- Auto-detect delimiter: comma, tab, semicolon, pipe
- Encoding support: UTF-8, UTF-8 BOM, UTF-16 LE/BE, Windows-1252, Latin-1
- Dark mode support
- Row number column
- macOS 12+ using the modern `.appex` extension format

# CSV Quick Look

A macOS QuickLook extension that gives CSV and TSV files a proper table preview — with virtual scrolling, column sort, row filtering, and full dark-mode support.

macOS ships with a plain-text preview for `.csv` files. CSV Quick Look replaces it with a spreadsheet-style view that handles files with hundreds of thousands of rows without breaking a sweat.

---

## Features

- **Instant preview** — press Space on any `.csv` or `.tsv` file in Finder
- **Virtual scroll** — renders only visible rows; handles 500 k+ row files smoothly
- **Column sort** — click any header to sort ascending/descending (numeric-aware)
- **Row filter** — live search across all columns, Escape to clear
- **Auto-detect delimiter** — comma, tab, semicolon, or pipe, chosen automatically
- **Encoding support** — UTF-8, UTF-8 BOM, UTF-16 LE/BE, Windows-1252, Latin-1
- **Dark mode** — follows the system appearance automatically
- **Row numbers** — always visible as a sticky left column
- **Truncation notice** — shown when the file exceeds the configured row limit

---

## Requirements

| | |
|---|---|
| macOS | 12 Monterey or later |
| Xcode | 15 or later (to build from source) |

---

## Build & Install

CSV Quick Look is not on the Mac App Store. You build it yourself in a few minutes.

### 1. Clone

```bash
git clone https://github.com/YOUR_USERNAME/csv-quick-look.git
cd csv-quick-look
```

### 2. Open in Xcode

```bash
open CSVQuickLook.xcodeproj
```

Or, if you use [XcodeGen](https://github.com/yonaskolb/XcodeGen):

```bash
xcodegen generate
open CSVQuickLook.xcodeproj
```

### 3. Update the bundle identifier

In `project.yml`, change the `bundleIdPrefix` to your own reverse-domain prefix:

```yaml
options:
  bundleIdPrefix: com.yourname   # ← change this
```

Then regenerate the project if using XcodeGen, or update the bundle IDs manually in Xcode's target settings.

### 4. Build and run

Select the **CSVQuickLook** scheme, choose **My Mac** as the destination, and press **⌘R**.

The app installs the QuickLook extension on launch.

### 5. Enable the extension

Open **System Settings → Privacy & Security → Extensions → Quick Look**, and enable **CSV Quick Look**.

> On macOS 12–13, the path is **System Preferences → Extensions → Quick Look**.

---

## Settings

Launch the **CSV Quick Look** app at any time to adjust:

| Setting | Default | Description |
|---|---|---|
| Auto-detect delimiter | On | Detects comma, tab, semicolon, or pipe automatically. When off, comma is used. |
| Max rows to display | 100,000 | Upper limit of rows loaded into the preview. Higher values use more memory. |

---

## How It Works

The extension is a standard macOS `QLPreviewingController` backed by a `WKWebView`. When QuickLook requests a preview:

1. **Swift** reads the file, detects encoding and delimiter, parses the CSV.
2. It loads a local `preview.html` page into the web view.
3. Once the page is ready, it calls `initTable(headers, rows, …)` via JavaScript injection.
4. **JavaScript** builds a virtual-scroll table — only the rows in the current viewport are in the DOM.

No third-party dependencies. No network access. Sandboxed.

---

## Project Structure

```
csv-quick-look/
├── Shared/
│   └── CSVParser.swift          # Encoding detection, delimiter sniff, RFC 4180 parser
├── CSVQuickLook/
│   ├── App.swift                # SwiftUI app entry point
│   └── ContentView.swift        # Settings UI
├── CSVQLExtension/
│   ├── PreviewViewController.swift  # QLPreviewingController + WKWebView
│   └── Resources/
│       ├── preview.html         # Page shell
│       ├── style.css            # Light + dark themes
│       └── table.js             # Virtual scroll, sort, filter
└── project.yml                  # XcodeGen spec
```

---

## Contributing

Pull requests are welcome. Please open an issue first to discuss significant changes.

To set up for development, follow the **Build & Install** steps above. The JavaScript frontend (`table.js`, `style.css`) can be edited without rebuilding the Swift target — just reload the preview.

---

## License

MIT — see [LICENSE](LICENSE).

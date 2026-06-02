# Security Policy

## Supported Versions

| Version | Supported |
|---|---|
| 1.x | ✅ |

## Reporting a Vulnerability

Please **do not** open a public GitHub issue for security vulnerabilities.

Instead, report them privately via GitHub's built-in security advisory feature:
**[Report a vulnerability](https://github.com/adamorad/csv-quick-look/security/advisories/new)**

Include:
- A description of the issue
- Steps to reproduce
- Potential impact

You can expect a response within 7 days. If the vulnerability is confirmed, a fix will be prioritised and released as soon as possible.

## Scope

CSV Quick Look is a sandboxed macOS QuickLook extension with no network access and no file write permissions. The attack surface is limited to maliciously crafted CSV/TSV files that could exploit the parser or the WKWebView renderer.

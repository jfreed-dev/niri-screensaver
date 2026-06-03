# Security Policy

## Supported Versions

niri-screensaver is in active pre-1.0 development. Security fixes target the
latest minor release on `main`. Older versions are not supported.

| Version  | Supported |
|----------|-----------|
| 0.6.x    | ✅        |
| < 0.6    | ❌        |

## Automated checks

`main` is branch-protected: every change lands through a PR that must pass CI
before merge. The gates that bear on security:

- **`shellcheck -x`** — static analysis on all four bash scripts, catching
  unquoted expansions, word-splitting, and unsafe `eval`/`source` patterns.
- **bats + kcov** — a unit suite over the bash, run under coverage in CI. The
  scripts source untrusted shell config (the plugin-written `config` file), so
  the tests pin the `load_config` defaulting and the launch-gating logic.
- **JSON validation, doc-links, typos, markdownlint, actionlint** — parse and
  hygiene checks on the manifest, i18n, docs, and the workflows themselves.

The screensaver runs unprivileged in the user session and shells out only to
tools the user already has (`tte`, `alacritty`, `niri msg`, `playerctl`). It
holds no secrets, opens no sockets, and never elevates.

## Reporting a Vulnerability

Please **do not** open a public issue for security-sensitive reports.

Email **<jon@freed-dev.com>** with:

- A description of the vulnerability and its impact
- Steps to reproduce or a proof of concept
- Affected version(s) and platform details

You should receive an acknowledgement within 7 days. Coordinated disclosure
is appreciated; we will work with you on a fix and release timeline before
any public details are shared.

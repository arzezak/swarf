# Changelog

## Unreleased

- The probe no longer kills the boot of apps using bootsnap on Ruby 4.0.2+, where
  dumping an instruction sequence under coverage raises. It sets
  `DISABLE_BOOTSNAP_COMPILE_CACHE=1` so bootsnap skips the part that would.

## 0.2.0 — 2026-09-06

- `swarf init` installs a Claude Code skill into `.claude/skills/swarf/` and adds
  `.swarf/` to `.gitignore`.

## 0.1.0 — 2026-09-05

Initial release.

# Changelog

## Unreleased

- The probe no longer kills the boot of apps using bootsnap on Ruby 4.0.2+, where
  dumping an instruction sequence under coverage raises. It sets
  `DISABLE_BOOTSNAP_COMPILE_CACHE=1` so bootsnap skips the part that would.
- A method with `rescue` no longer scores 0% when tests ran it but never raised.
  Ruby's `Coverage` records no branch for `rescue`, so a branch inside the
  handler was the only one measured. Each rescue now adds its own outcomes: the
  body ran, and each handler ran.

## 0.2.0 — 2026-09-06

- `swarf init` installs a Claude Code skill into `.claude/skills/swarf/` and adds
  `.swarf/` to `.gitignore`.

## 0.1.0 — 2026-09-05

Initial release.

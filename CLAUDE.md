# Claude Code Project Notes

## Android toolchain: AGP pinned to 8.x

We've deliberately reverted to **AGP 8.13.2 / Gradle 8.14.4** and are no
longer on AGP 9. Reason: Flutter's Gradle plugin throws a `NullPointerException`
under AGP 9's new DSL, and the `android.newDsl=false` workaround triggers a
secondary failure where Flutter plugins that apply `kotlin-android` (e.g.
`package_info_plus` v10) conflict with AGP 9's pre-registered `kotlin`
extension. None of the cirruslabs Flutter images we tested (`3.41.6`, `stable`,
`beta` = `3.43.0-0.3.pre`) ship a fix.

### Watching for the unblock

Renovate will keep opening MRs for:

- `com.android.application` major version 9.x
- `ghcr.io/cirruslabs/flutter` newer tags

**When one of those MRs opens, try merging it.** A fix can come from either
side — newer Flutter Gradle plugin, or newer AGP — and the quickest way to
know it landed is to let the CI pipeline (including `build:android`) run
against the bump.

If the MR's pipeline passes green, merge it and remove this section from
`CLAUDE.md`. If it fails the same way as before (Flutter Gradle plugin NPE,
or kotlin-android extension conflict), close the MR with a reference to this
file and wait for the next one.

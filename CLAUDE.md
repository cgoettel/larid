# Claude Code Project Notes

## Android toolchain: AGP pinned to 8.x (Flutter has paused AGP 9 support)

Current state: **AGP 8.13.2** with **Gradle 9.4.1** (Gradle 9 builds fine
against AGP 8). We are intentionally not on AGP 9.

The reason is upstream policy, not just a build error. Flutter has officially
paused AGP 9 support — its migration guide (`docs.flutter.dev/release/breaking-changes/migrate-to-agp-9`)
returns 404 and Flutter's docs explicitly say not to migrate yet. The pause is
because AGP 9 makes Kotlin built-in and rejects the `kotlin-android` plugin,
which every Flutter plugin's `android/build.gradle` still applies (sqflite_android,
package_info_plus, shared_preferences_android, etc.). The plugin ecosystem has
to migrate first; we can't fix it from the app side.

Layers we've already cleared (don't re-test):

- Flutter Gradle plugin NPE under AGP 9 — fixed in current Flutter (3.41.7)
- Gradle 8.x too old for AGP 9.2.0 — Gradle 9.4.1 is now on main

The remaining blocker is the kotlin-android plugin conflict in pub-sourced
Flutter plugins.

### Watching for the unblock

The signal we're waiting for is **Flutter resuming AGP 9 support**, not just
a higher AGP or Gradle version. Concrete things to watch:

- A `cirruslabs/flutter` image newer than `3.41.x` stable (currently all
  3.42+ tags are `.pre` betas)
- Flutter blog/release notes announcing AGP 9 support
- The Flutter migration guide URL coming back online

When any of those land, recreate the closed AGP 9 MR via the dependency
dashboard and run a CI pipeline against it. If `build:android` is finally
green, merge it and delete this section.

## Renovate

Dependency MRs in this repo are opened by the self-hosted Renovate bot
running as a CronJob in the smart-home k3s cluster (namespace
`renovate`). larid is **slot 0** of the 3-week ISO-week-mod-3 rotation
— scanned every third Saturday, paired with cocktails (both Flutter).

Run `/renovate larid` to review what the bot opened. Architecture,
runbook, rollback procedure, token rotation:
[smart-home/docs/renovate-bot.md](https://gitlab.com/colby.goettel/smart-home/-/blob/main/docs/renovate-bot.md).

## Code review before MRs

Run `/code-review` before opening an MR on any non-trivial logic change — an
independent pass catches bugs that inline self-review misses (the same author
reviewing their own diff carries the same blind spots), which matters most for
AI-authored code. Default to `medium`/`high` effort; both run in-session on the
existing plan.

**The `ultra` tier is forbidden — never run it.** It executes a multi-agent
review in the cloud and bills as metered extra usage on top of the subscription
(reportedly ~$5–$20 per run), separate from and on top of the plan. There is no
scenario where it is worth the charge.

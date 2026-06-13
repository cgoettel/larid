# Claude Code Project Notes

## Android toolchain: AGP pinned to 8.x pending built-in-Kotlin migration

Current state: **AGP 8.13.2** with **Gradle 9.5.1**, Flutter **3.44.0** CI
image, Kotlin plugin **2.4.0**. We are intentionally still on AGP 8 — but the
reason changed in June 2026 (see below).

### What changed: Flutter 3.44 resumed AGP 9 support

Flutter previously *paused* AGP 9 support; that pause is over. Flutter 3.44
(June 2026, first stable past 3.41.x) restored AGP 9 support via **built-in
Kotlin**. The old migration guide URL (`migrate-to-agp-9`) still 404s — not
because the work is paused, but because it was **renamed** to
[`migrate-to-built-in-kotlin`](https://docs.flutter.dev/release/breaking-changes/migrate-to-built-in-kotlin).
(So the old "is the URL back online?" watch check is now misleading — drop it.)

The core conflict is unchanged: AGP 9 makes Kotlin built-in and rejects the
`kotlin-android` plugin that pub-sourced Flutter plugins still apply. Flutter
3.44's fix is a **temporary compatibility shim** — its tooling auto-writes
`android.builtInKotlin=false` and `android.newDsl=false` into `gradle.properties`
at build time, letting the legacy plugin keep working *during migration*. Those
flags are explicitly temporary and will be removed in a future Flutter.

### Why we're still on AGP 8 (decision: wait for the plugins)

Two reasons:

1. The clean destination is the **built-in-Kotlin migration** (remove the
   `kotlin-android` plugin, adopt built-in Kotlin), not a bare AGP version bump.
   A bare bump to AGP 9 only builds by leaning on the temporary shim above —
   debt that breaks when Flutter removes the flags.
2. The plugin ecosystem hasn't migrated yet (tracking: flutter#181383). Until
   pub plugins (sqflite, package_info_plus, shared_preferences, …) drop
   `kotlin-android`, the clean migration isn't possible from the app side.

**The decision (2026-06-13): stay on AGP 8 and wait.** AGP 8.13.2 is current
and fully supported, and there's no deadline. Rather than adopt the temporary
shim now and unwind it later, we wait for flutter#181383 to clear the plugin
side, then do the clean built-in-Kotlin migration in one move — skipping the
shim era entirely. Don't merge a Renovate AGP-9 version bump in the meantime.
The clean migration is tracked in **larid#18**.

### CI probe result (2026-06-13)

A bare AGP 9 bump MR was recreated via the dependency dashboard to probe
whether `build:android` is green under AGP 9.2.1 + Flutter 3.44's shim. It
**was green** — the build log showed `Upgrading gradle.properties` (the shim
injecting flags) and a real `app-release.apk` built. The MR was **closed, not
merged**: the shim flags live in the ephemeral CI workspace and aren't
committed, so a bare bump isn't a clean AGP 9 state. Treat a green probe as
information only — it confirms the shim carries our build, nothing more.

Layers already cleared (don't re-test):

- Flutter Gradle plugin NPE under AGP 9 — fixed in Flutter 3.41.7+
- Gradle 8.x too old for AGP 9.2.0 — on Gradle 9.5.1 now

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

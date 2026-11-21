# Claude Code Project Notes

## Roadmap

Open work lives in [`ROADMAP.md`](ROADMAP.md): the Agent-ready lane and the parked
items, with why they are parked. Read it before picking up work; a newly filed issue
gets its entry there, not here. This file is rules, architecture and current state only.

## Android toolchain: AGP 9 with built-in Kotlin

Current state: **AGP 9.5.2** with **built-in Kotlin**, Gradle **9.9.2** (AGP 9.5
needs 9.6.0 or newer). The app no longer applies `kotlin-android`; Kotlin comes
from AGP itself, and `app/build.gradle.kts` keeps a top-level
`kotlin { compilerOptions { jvmTarget } }` block per Flutter's
[built-in Kotlin guide](https://docs.flutter.dev/release/breaking-changes/migrate-to-built-in-kotlin/for-app-developers)
(larid#18).

**`settings.gradle.kts` still declares `org.jetbrains.kotlin.android ... apply false`,
on purpose.** It's never applied; declaring it pins the Kotlin version AGP
compiles with. Without it AGP falls back to its bundled Kotlin 2.2.10, below
Flutter's 2.2.20 minimum, and `build:android` fails. Renovate keeps bumping it as
before.

**`android/gradle.properties` sets the two AGP 9 flags explicitly:**

- `android.builtInKotlin=true`: without it, Flutter's migrator writes its
  temporary opt-out (`false`) at build time, the "shim" that lets legacy
  `kotlin-android` plugins keep working. A build log line `Upgrading gradle.properties` means the flag went missing.
- `android.newDsl=false`: Flutter's Gradle plugin still targets the legacy AGP
  DSL. Flip it only when Flutter drops the old DSL
  ([flutter#184839](https://github.com/flutter/flutter/issues/184839)).

**Flutter 3.50 and later require AGP 9.1.1 or newer**, so AGP 8 is no longer an
option. If a pub plugin still applies `kotlin-android`, the Android build fails
to compile: check the plugin's changelog for a built-in Kotlin release before
reaching for the shim.

**CI images: `ghcr.io/gmeligio/flutter-android`, plus `flutter-web` for
`build:web`** (the Android image has web disabled; Renovate groups the two). The old
`ghcr.io/cirruslabs/flutter` stopped publishing on May 1, 2026 (Cirrus Labs
wound down after an acquisition; cirruslabs/docker-images-flutter#429), frozen
at 3.44.0. gmeligio's image tracks Flutter stable, tags by exact version (no
`latest`), runs as a rootless `flutter` user, and is amd64-only: run it locally
with `docker run --platform linux/amd64`.

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

# larid — roadmap

Open work only; the issue tracker is the live source of truth. **Agent-ready** is
specified enough for an unattended session; **Parked** waits on Colby, with the
reason it is parked. Shipped work is removed from here, never marked done. Rules
and architecture live in [`CLAUDE.md`](CLAUDE.md).

## Agent-ready

- [#22 "Move the GitLab-to-GitHub mirror recipe out of agent memory"](https://gitlab.com/colby.goettel/larid/-/work_items/22) (`Agent-ready`, `priority::months`, milestone Platform) — the `mirror_to_github` recipe seven repos use lives only in agent memory; write it up as a doc and drop the toolchain memory that has drifted from `CLAUDE.md`.
- [#23 "Add README badges"](https://gitlab.com/colby.goettel/larid/-/work_items/23) (`Agent-ready`, `priority::weeks`, milestone Platform) — pipeline and GPL-3.0 license badges at the top of the README, and run `run_tests` on `main` so the pipeline badge covers the tests, not just the builds.

## Parked

Someday, and needs Colby present.

- [#21 "Staff-engineer handover: knowledge transfer and "what would you do differently?""](https://gitlab.com/colby.goettel/larid/-/work_items/21) (`Present`, `priority::someday`, milestone Platform) — a one-session exercise where an agent plays a staff engineer inheriting the repo: a knowledge-transfer interview with Colby (answers folded into the docs), then a proposal of what the agent would do differently, discussed before anything is filed. Deliberately parked; not running yet.

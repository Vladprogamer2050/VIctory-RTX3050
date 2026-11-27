# VIctory RTX 3050 Lab Archive

**Archive snapshot:** 2026-11-27  
**Test machine:** Windows 10 Pro, Ryzen 5 5600, GeForce RTX 3050 8 GB, 16 GB system RAM.

This archive documents a short, intensive community research effort around running an Xbox Series game build through the open-source VIctory compatibility layer on a modest Windows PC. It preserves the sequence of checkouts, experiments, failures, test observations and upstream projects examined between 2026-11-25 and 2026-11-27.

It is a research log, not a new game port, compatibility guarantee, benchmark leaderboard or distribution channel.

## Start here

- [Timeline](LAB_TIMELINE.md) — what happened, in date order.
- [Fork catalogue](FORK_CATALOG.md) — local checkouts and their upstream repositories, pinned to commits observed on this machine.
- [RTX 3050 results](RTX3050_RESULTS.md) — local measurements, and what they do and do not prove.
- [Local lab inventory](LOCAL_LAB_INVENTORY.md) — what was preserved on the test PC and what was deliberately excluded from publication.

## Why preserve this?

The community landscape moved quickly. Multiple forks explored different approaches to shader translation, memory residency, texture streaming, command submission, ray tracing and low-VRAM operation. A local checkout can disappear, a branch can move, and a successful launch can be confused with a playable game.

The purpose of this archive is to make the experiment traceable:

1. Record the repository and commit that was tested, not just the project name.
2. Separate our machine's observations from performance figures claimed by upstream authors.
3. Keep failed tests and reverted experiments visible, so other researchers do not repeat dead ends without context.
4. Record the exact hardware and memory constraints behind every local result.
5. Link back to original repositories and contributors rather than mirroring their code.

## Evidence labels

- **Observed locally** — recorded from this lab's process output, test log, or Git checkout.
- **Upstream-reported** — stated by the original project's author; not independently reproduced here.
- **Microbenchmark** — a synthetic workload; it is not an in-game result.
- **Unverified** — incomplete, early-loading-only, or otherwise insufficient to support a performance claim.

## Scope and distribution policy

This repository does **not** contain the game executable, game dump, extracted game archives, copyrighted textures, shader caches, memory dumps, proprietary assets, or copies of third-party release binaries. It contains our own notes, aggregate observations, commit identifiers and links to the original public projects.

To reproduce a test, obtain game files independently and lawfully, then follow the upstream project's own instructions and licence.

This project is unofficial, independent and not affiliated with or endorsed by Rockstar Games, Take-Two Interactive, Microsoft, AMD, NVIDIA or the maintainers of the referenced projects. Product and project names are used only to identify the work being researched.

## Update policy

New entries should include the date, local hardware, exact repository/commit, console profile, scene, cache state, relevant settings, measured frame time and memory use. A result should not be called an improvement unless the comparison uses sufficiently similar conditions. Menus, loading screens and game-world scenes must be reported separately.

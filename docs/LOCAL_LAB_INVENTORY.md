# Local Lab Inventory

**Inspected:** 2026-11-27  
**Root:** D:\GTA6_port

This document records the structure of the local research workspace so that the archive has a map of what was actually retained. Paths are relative to the lab root. Commit pins are in [FORK_CATALOG.md](FORK_CATALOG.md).

## Active and reference checkouts

- cold-project-vi-edupode/ — clean local baseline checkout, currently on experiment/agility-sdk.
- victory-belobug-amd/ — Belobug fork; local Agility SDK experiment files are uncommitted.
- cgbj-fork-recovered/ — recovered public mirror checkout.
- vice-tay-cgbj-line/ — separate CGBJ-related checkout.
- victory-7900xtx-donor/ — high-end Radeon reference checkout.
- research-20261125/victory-fork/ and research-20261125/ztrx/ — pinned research snapshots.
- new-donors-readonly/ — five read-only donor snapshots for NVIDIA 8 GB and performance comparisons.
- upstream-research/VIPort/ — separate research checkout; contains an untracked fetched-source folder locally.

## Preserved experiments and backups

- backups/retired-experiments-20261126/victory-fxceless/ — retired performance experiment with multiple local branches and uncommitted changes.
- backups/retired-experiments-20261126/victory/ — preserved upstream checkout with staged local Windows 10 Agility SDK changes.
- backups/pre-graphics-fixes-20261126/, backups/pre-mesh-wave64-20261126/ and backups/pre-unification-20261126/ — Git bundles, status captures, untracked-file snapshots and patch files.
- Other backups/pre-* directories — checkpoints created before individual experiments.
- upstream-research/ — patch files and research scripts, including mesh-wave and texture experiments.
- victory-frametime.patch, OPTIMIZATION_PLAN.md and the owner/descriptor backup folders — local research artifacts.

These snapshots were preserved for provenance. A patch file is not automatically safe or correct to apply to a different commit.

## Excluded from this GitHub archive

The following content stays on the local PC and is not published here:

- The game installation and game dump under D:\GTA6\.
- victory-belobug-cache/ and victory-belobug-data/, which contain runtime cache/data rather than general research notes.
- Build output such as Rust target/ directories, local executables, PDBs and generated runtime DLLs.
- julias-launcher-0.3.5/ binaries, including the launcher, setup program and victory.exe; the original release page is linked instead.
- Local victory.toml files, because they may contain machine-specific game paths and runtime settings.
- Screenshots, shader caches, extracted archives, memory dumps, crash dumps and any game-derived assets.
- Git working-tree contents from retired experimental branches unless each file is independently reviewed and approved for publication.

## Preservation principles

- Do not delete a checkout merely because it is no longer the active baseline; record the commit and preserve it in a dated backup.
- Do not publish raw game data or cache directories.
- Keep donor repositories as links and pinned commit references; retain their original attribution and licences.
- Do not publish local uncommitted changes as though they were an upstream release.
- When a build output or cache is removed to reclaim disk space, preserve the source commit, relevant logs and a short note explaining what was removed.

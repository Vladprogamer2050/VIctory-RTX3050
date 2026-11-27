# Fork and Checkout Catalogue

The commit identifiers below were observed in the local workspace on **2026-11-27**. They are inventory pins, not endorsements, performance rankings or claims that every checkout was run successfully. Links point to the original repositories; this project does not mirror their source.

## Main VIctory lineage and working baselines

| Local checkout | Original repository | Local ref / commit | Purpose and notes |
|---|---|---|---|
| cold-project-vi-edupode | [edupode/cold-project-vi](https://github.com/edupode/cold-project-vi) | experiment/agility-sdk / 0c6bae9; local main / 9ec07f2 | Clean local baseline selected on 2026-11-26. Local Agility SDK work is on its own branch; working tree was clean at inventory. Tags v2026.11.25, v2026.11.26, v2026.11.26b and v2026.11.26c were present. |
| victory-belobug-amd | [Belobug/VIctory-Belobug-AMD](https://github.com/Belobug/VIctory-Belobug-AMD) | a-publier / cd8dfc0; local experiment/agility-sdk points to the same commit | AMD-oriented fork collected for comparison. Local Windows 10 Agility SDK changes existed as uncommitted files; they were not pushed upstream. |
| cgbj-fork-recovered | [Pavl3000/cgbj-fork](https://github.com/Pavl3000/cgbj-fork) | main / 2eb9b22 | Recovered public mirror checkout; clean at inventory. The folder name records the lab's recovery context, not project ownership. |
| vice-tay-cgbj-line | [TaynanGT/Vice-Tay](https://github.com/TaynanGT/Vice-Tay) | main / a5491e4 | Separate CGBJ-related line, clean at inventory. |
| upstream-research/VIPort | [DesertGamer/VIPort](https://github.com/DesertGamer/VIPort) | main / 59b7938 | Separate compatibility-layer research checkout. It had an untracked _fetched folder locally; that folder was not published. |
| research-20261125/victory-fork | [fxceless/victory-fork](https://github.com/fxceless/victory-fork) | main / 9376fd6 | Pinned upstream research snapshot, clean at inventory. |
| research-20261125/ztrx | [Zettrox/ztrx](https://github.com/Zettrox/ztrx) | main / 90b529f | Separate launcher/runtime experiment snapshot, clean at inventory. |
| backups/retired-experiments-20261126/victory | [JMAN730/victory](https://github.com/JMAN730/victory) | agility-sdk-local / b8d4a45 | Preserved upstream checkout with staged local Windows 10 SDK changes. Kept in backups; not published from this archive. |

## NVIDIA and low-memory donor snapshots

These were collected for reading and comparison. They were kept under new-donors-readonly/ and were clean at inventory.

| Local checkout | Original repository | Commit |
|---|---|---|
| new-donors-readonly/dexnom-victory | [DexNom/VIctory](https://github.com/DexNom/VIctory) | 64bd58f |
| new-donors-readonly/dolberthi-neptune-nvidia-8gb | [Dolberthi/neptune-dolberth-nvidia-8gb](https://github.com/Dolberthi/neptune-dolberth-nvidia-8gb) | 485ca0a |
| new-donors-readonly/lordon1a-victory-laptop-8gb | [lordon1a/victory-laptop-8gb](https://github.com/lordon1a/victory-laptop-8gb) | dbdf7fb |
| new-donors-readonly/soldsawn-victory-nvidia-8gb | [soldsawn/victory-nvidia-8gb](https://github.com/soldsawn/victory-nvidia-8gb) | c09a44e |
| new-donors-readonly/zsy-miao-victory-perf | [zsy-miao/victory-perf](https://github.com/zsy-miao/victory-perf) | 52a6094 |

## High-end / alternative hardware reference

| Local checkout | Original repository | Commit | Why it was collected |
|---|---|---|---|
| victory-7900xtx-donor | [avatarmanz/VIctory-7900XTX](https://github.com/avatarmanz/VIctory-7900XTX) | c9c932c | Reference work from a high-end Radeon target; not a direct RTX 3050 performance comparison. |

## Retired local experiment branch

| Local checkout | Ref / commit | State at inventory |
|---|---|---|
| backups/retired-experiments-20261126/victory-fxceless | experiment/pr1007-heap-worker-20261125 / cf3f06d | Preserved with modified and untracked files. Numerous local branches remain in its Git database. It is a historical working tree, not a clean reproducible release. |

Notable branch/checkpoint names in that retired checkout include:

- experiment/fps-copy-plain-20261125 — 371c868
- experiment/fps-a253706-20261125 — 399b4b6
- experiment/pr1043-sync-heap-20261125 — 07c0d5b
- upgrade/portwatch-20261125 — 0e0481f
- experiment/rt-builder-20261125 — 711a204
- experiment/rt-builder-lds-20261125 — ee0a418

## Launcher release tracked separately

- [Julia's Launcher v0.3.5 release](https://github.com/felicienradio/cold-project-vi/releases/tag/v0.3.5) — release assets were downloaded and SHA-256-verified locally on 2026-11-27.
- The launcher, setup executable and victory.exe are **not** mirrored in this repository. Use the original release page for its assets.

## Important interpretation

A local checkout only proves that a version was collected. A clean Git tree only proves that the checkout had no tracked/untracked changes at the time of inspection. Neither fact proves that the program built, launched or worked in-game. See [the results log](RTX3050_RESULTS.md) for what was actually observed.

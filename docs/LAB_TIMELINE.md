# Lab Timeline — 2026-11-25 to 2026-11-27

This is a chronological record of the local RTX 3050 experiment. Times are not listed where the preserved notes do not establish them reliably.

## 2026-11-25 — First performance-focused experiments

The lab concentrated on the fxceless-based VIctory fork and began treating the test PC as a constrained target rather than assuming results from higher-end GPUs would transfer.

Work included:

- Building repeatable diagnostic launch profiles and Series S selection.
- Adding frame summaries, card timing, CPU sampling and memory-safety checks to the local launcher.
- Investigating descriptor/heap synchronization, command preparation, title-memory copies, copy-back and DirectStorage worker scheduling.
- Trying isolated branches for plain-copy paths, indirect-draw windows, queue scheduling, asynchronous submission and background texture/heap work.
- Keeping experimental changes behind switches and preserving checkpoints before risky integrations.

The tests exposed very high memory pressure. One recorded gameplay run reached about 1 FPS (roughly 1,006 ms in its last summary) before being stopped with approximately 1.08 GB of free physical RAM. Other heavy-world samples were lower. Menu and loading frames near 30 FPS were not representative of the world.

A synthetic indirect-draw microbenchmark showed that one 32-record window configuration could reduce the GPU time of the synthetic clamp workload from about 43.5 ms to about 1.12 ms. This was useful for understanding that isolated code path, but it did not establish an in-game FPS gain: the corresponding gameplay run emitted very few indirect commands.

A baseline-versus-balanced comparison was also attempted. The sample counts and draw workloads differed, and memory pressure stopped the tests early. The result was therefore marked **inconclusive**, not a win.

## 2026-11-26 — Fork collection and clean baseline

The local workspace was reorganised after several rounds of experiments. Old working copies were moved into a dated backup folder instead of being destructively deleted. Build output directories were removed from retired checkouts to reclaim disk space; source trees, Git history, patches and selected repository bundles were retained.

A clean checkout of [edupode/cold-project-vi](https://github.com/edupode/cold-project-vi) was selected as a separate baseline. Its local main branch was at 9ec07f2; the local Windows 10 compatibility work was kept on experiment/agility-sdk at 0c6bae9. The local working tree was clean at the time of inventory.

The lab also cloned [Belobug/VIctory-Belobug-AMD](https://github.com/Belobug/VIctory-Belobug-AMD) into its own directory. The checked-out public branch tip was cd8dfc0. A separate local experiment/agility-sdk branch contains additional uncommitted Windows 10 SDK integration files; those changes were not pushed to the author's repository.

### Windows 10 / D3D12 compatibility finding

The clean baseline initially reached D3D12 device creation on the RTX 3050 but then failed during early pipeline creation. The logs showed unsupported root-signature flag combinations (c00 / c01) followed by an access violation (0xC0000005).

The working diagnosis was that the system D3D12 runtime exposed an older shader-model capability level than the project required. Agility SDK 1.620.2 was integrated locally in a separate experiment branch. After that change, the runtime configuration reported SDK version 620 and the earlier root-signature messages stopped appearing in the subsequent launch log.

This is evidence that the SDK integration changed the startup path on this Windows 10 machine. It is not proof that all pipelines, graphics features or gameplay scenes are correct.

A later launch produced frame-presentation messages and an approximately 28–30 FPS counter during an early loading stage. It also continued loading game resources. This was explicitly recorded as **early-stage rendering**, not a 28–30 FPS gameplay benchmark.

## 2026-11-27 — Launcher release

[Julia's Launcher v0.3.5](https://github.com/felicienradio/cold-project-vi/releases/tag/v0.3.5) was downloaded to the local lab in a dedicated folder.

The following release assets were downloaded and their SHA-256 values matched the hashes published in the release metadata:

- Julias-Launcher.exe
- VI-Setup-0.3.5.exe
- victory.exe

The portable launcher process was started. The installer was retained but not run. Starting the launcher was not treated as proof that the full game had launched or that a gameplay scene was playable.

The v0.3.5 release notes describe deeper automatic detection of a complete game dump and a check that shader preparation produced a plausible shader count. Those are launcher checks; they do not themselves improve rendering performance.

## Current conclusion at the archive date

By 2026-11-27, the lab had successfully built several forks, confirmed D3D12 device creation on the RTX 3050 after a local Agility SDK integration, and reached frame presentation during early loading. The local evidence did **not** establish a stable, playable open-world frame rate on this 16 GB system.

The most useful outcome so far is a traceable collection of versions and test results, including the failures and caveats.

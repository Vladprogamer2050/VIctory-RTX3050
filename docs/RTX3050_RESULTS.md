# RTX 3050 Lab Results and Caveats

**Snapshot date:** 2026-11-27  
**System:** Windows 10 Pro build 19045, AMD Ryzen 5 5600, NVIDIA GeForce RTX 3050 8 GB, 16 GB RAM.  
**Test target:** Xbox Series game build launched through VIctory-derived projects.

These are observations from one machine and several different builds and scenes. They are not a controlled comparison across all forks.

## Observations

| Test / build | Observation | Evidence quality |
|---|---|---|
| Earlier VIctory world attempts, 2026-11-25 | Heavy gameplay samples were around 0.3–1.4 FPS in one diagnostic run; the last recorded summary was about 1.0 FPS / 1,006 ms per frame. | Local diagnostic log; scene and workload specific. |
| Memory-pressure tests, 2026-11-25 | One run was deliberately stopped around 1.08 GB free physical RAM. A later balanced run stopped around 0.71 GB. | Local process/memory observations. |
| Synthetic indirect-draw test | 3,200 synthetic indirect draws; one 32-record clamp configuration measured about 1.12 ms versus about 43.5 ms for the old synthetic windowed clamp. | Microbenchmark only; **not** in-game FPS. |
| Baseline vs. balanced profile | Sample counts and draw workloads differed, and both tests were cut short by memory pressure. | Inconclusive; do not claim a performance gain. |
| Clean edupode baseline before Agility SDK | D3D12 device creation succeeded on the RTX 3050; early pipeline creation logged unsupported root-signature flag sets (c00 / c01), followed by an access violation (0xC0000005). | Local launch log. |
| Local Agility SDK 1.620.2 integration | Runtime configuration reported SDK version 620. The earlier root-signature flag errors stopped appearing in the subsequent run. | Local config and launch log; not a full feature-compatibility result. |
| Post-SDK early loading | The log recorded frame presentation and a counter around 28–30 FPS while game resources were still loading. | **Unverified for gameplay**; must not be presented as a world-scene benchmark. |
| Belobug fork on this Windows 10 system | The fork was built locally; a later run reached D3D12 device readiness and frame presentation after the separate SDK experiment. Some unsupported pipeline warnings remained. | Partial startup/rendering evidence; stable gameplay not confirmed. |
| Julia's Launcher v0.3.5 | Portable launcher started on the PC. Release assets were downloaded and their SHA-256 values matched the release metadata. | Verified download and process start; not proof of game launch or playability. |

## Memory and test safeguards

The lab's working plan used a conservative preflight of at least **6 GB free physical RAM** before a world test and a stop threshold near **1 GB free**. These are local safety thresholds derived from previous tests, not universal requirements.

A recorded gameplay session showed the test process growing to roughly 14.3 GB of private/committed memory while physical free RAM fell to about 1.08 GB. This makes the 16 GB system's memory pressure a first-class variable. Page-file use, shader-cache state and background applications can change the result significantly.

## What the tests suggest

- The bottleneck was not constant across every scene. Some early diagnostic windows were host-side preparation/submission and memory-copy bound; the GPU and pipeline workload changed as the game loaded more content.
- An optimization measured on a synthetic draw stream cannot be assumed to improve a real scene that emits few indirect draws.
- A menu or loading counter is not comparable to a stable world-scene frame rate.
- More aggressive memory-residency experiments can reduce copies but can also exhaust committed memory or cause driver/device failure on an 8 GB GPU with 16 GB system RAM.
- The Agility SDK integration improved the early D3D12 startup path on Windows 10, but does not prove that every shader, pipeline, texture format or ray-tracing path works.

## What is not established

As of 2026-11-27, this lab had **not** established:

- a stable, playable open-world session on the RTX 3050 / 16 GB system;
- a repeatable, controlled FPS improvement attributable to one local patch;
- visual parity with the original console;
- long-session stability for the latest local builds;
- compatibility with every RTX 3050 driver, Windows installation or game dump.

## How to add a useful result

Please include:

1. CPU, GPU and VRAM, system RAM, Windows build and driver.
2. Exact project URL, branch, commit and build profile.
3. Console profile and exact scene/checkpoint.
4. Cold or warm shader cache, and whether the scene was still loading.
5. Average/median frame time and FPS over a stated interval.
6. Process memory, free physical RAM, committed memory and VRAM use.
7. Whether the test ended naturally, was stopped manually or crashed; include the exit code and relevant log excerpt.

Keep synthetic tests, loading tests and gameplay tests in separate rows.

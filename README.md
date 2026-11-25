# VIctory — RTX 3050 experiments

An experimental research fork focused on running and profiling an Xbox Series title through [VIctory](https://github.com/Marvisak/VIctory) on a modest Windows PC.

This repository is a fork of [fxceless/victory-fork](https://github.com/fxceless/victory-fork), which itself builds on the original VIctory project. The goal here is not to claim a new compatibility layer, but to test renderer, memory, shader and submission changes on a Ryzen 5 5600 + GeForce RTX 3050 system and publish measurements that may help other low-end test configurations.

**No game executable, game data, keys or copyrighted assets are included.** You must provide your own legally obtained game files. This project is unofficial and is not affiliated with or endorsed by the game's developer or publisher.

## Current test system

| Component | Configuration |
|---|---|
| OS | Windows 10 Pro, build 19045 |
| CPU | AMD Ryzen 5 5600 — 6 cores / 12 threads |
| GPU | NVIDIA GeForce RTX 3050 — 8 GB |
| System memory | 16 GB |
| Console profile | Xbox Series S |
| Build used for profiling | Rust diagnostic build, D3D12 |

Results are specific to this machine and can vary substantially with scene, camera position, shader cache, memory pressure and build options.

## Current status — 25 November 2026

- The program starts, reaches the menus and loads into the game world.
- The world renders, but it is **not playable** on this test system.
- Recent diagnostic windows measured roughly **2.5–3.0 FPS** (333–406 ms median frame time).
- Rendering and lighting are still incomplete; a successful world load does not mean visual parity with the console.
- Memory use is high. During the latest run, free physical RAM approached 1.9–2.1 GB, so tests use a conservative memory stop threshold.
- The figures above are observations from diagnostic runs, not a controlled benchmark or a promise of performance.

## What this fork is investigating

The work is focused on finding and measuring the bottlenecks that matter on this particular CPU/GPU combination:

- D3D12 command preparation and submission overhead.
- Descriptor-heap mirroring and redundant per-slot work.
- Copy-back traffic between the title's memory and the host-side GPU representation.
- DirectStorage worker scheduling on a 6-core / 12-thread CPU.
- Memory pressure, texture uploads and shader translation costs.

Recent local experiments selectively adapt ideas from community pull requests in the upstream fork:

- [PR #1043 — descriptor and heap synchronization work](https://github.com/fxceless/victory-fork/pull/1043). A targeted subset was ported locally, with a regression test for a heap-buffer slot being re-queued by the pass that just mirrored it.
- [PR #1044 — size the DirectStorage worker pool to physical cores](https://github.com/fxceless/victory-fork/pull/1044). The local build detected six physical cores and started six workers. **A performance gain has not been demonstrated on the RTX 3050 test system.**

These changes are being evaluated in a local experiment branch and should not be assumed to be present in this repository's default branch until they are published here. We report an optimization as successful only after comparable measurements; copying a patch is not the same as proving it helps this machine.

A larger candidate under review is [PR #1007 — background worker for heap-indexed texture uploads](https://github.com/fxceless/victory-fork/pull/1007). Its reported gains were measured on a different GPU and CPU, so they cannot be transferred to this system without testing.

## Build and run

For the upstream requirements, build steps, command-line options and runtime configuration, use the [upstream VIctory README](https://github.com/Marvisak/VIctory#readme) and the [fxceless fork](https://github.com/fxceless/victory-fork). This README intentionally avoids copying their full setup guide; those instructions belong with their respective projects and may change independently.

Local diagnostic launcher notes and experiment records are maintained in this repository as they are published.

## Credits and license

- **[VIctory](https://github.com/Marvisak/VIctory)** by Marvisak and its contributors provides the original compatibility layer and core architecture.
- **[fxceless/victory-fork](https://github.com/fxceless/victory-fork)** is the direct base for this repository.
- **[XCL](https://github.com/ivall/xcl)** was consulted as a behavioral reference; it is a separate project.
- Some inherited memory-view and kernel-read work originates from **[myokex/victory-amd](https://github.com/myokex/victory-amd)** and **Joshua Odom**. Their original attribution and commit history are retained in the relevant source history.
- Community pull requests are credited individually above and in the code/history where their changes are used.

This project is licensed under **GPL-3.0-or-later**. See [LICENSE](LICENSE). The original projects and their contributors retain credit for their work.

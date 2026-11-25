# RTX 3050 test notes

Local test machine:
- Windows 10 Pro x64
- Ryzen 5 5600
- NVIDIA GeForce RTX 3050 8 GB
- 16 GB system RAM

## First successful world entry — 2026-11-25

The earlier local build reached gameplay/cutscenes and rendered scene content.
It was not playable.

| Metric | Recorded value |
|---|---:|
| Frame rate | about 1 FPS |
| Frame time | 1,227.8 ms |
| Draw calls | 3,145/frame |
| VIctory working set | 4.83 GB |
| Free physical RAM | 0.57 GB |
| Process state | responding |

These are measurements from the older build, not from the updated branch.

## Updated code — 2026-11-25

Imported the latest public `fxceless/victory-fork` changes through commit
`9376fd6`, including descriptor synchronization, draw-slot lifetime,
write-watch, texture/card-memory and shader translation improvements.

The upstream README reports roughly 2–5 FPS (190–450 ms/frame) on a different
machine with an RTX 4070 12 GB and 32 GB RAM. It also reports around 24 GB
system-memory use during gameplay. These results are reference data only;
they are not expected or guaranteed results on this RTX 3050 system.

## A/B test procedure

1. Close memory-heavy applications and record available RAM.
2. Run `tools/Run-VIctory.ps1 -Profile baseline`.
3. Record FPS, frame time, draw calls, process RAM, free RAM and GPU use.
4. Repeat the same point with `tools/Run-VIctory.ps1 -Profile balanced`.
5. Compare only runs made at the same scene and similar cache-warm state.

The balanced profile changes only `VICTORY_RELAY=2`. Riskier experimental
switches (in-place memory, on-demand texture levels, indirect windows and
wide-wave paths) are deliberately not enabled by the launcher.

Do not leave a run stalled at seconds per frame while Windows is exhausting
physical memory. Stop the experiment and preserve the log instead.

## Windows 10 test runtime

The GPU unit-test harness now exports Agility SDK 1.620 selectors and loads
the matching runtime from the profile's sibling D3D12 folder. This avoids a
false E_INVALIDARG from the in-box runtime when a test creates a directly
indexed root signature. The previously failing depth-bounds integration test
passes with this test-only runtime setup.

## Workspace test results — 2026-11-25

- `victory-gpu`: 144 passed, 0 failed, 3 ignored. The depth-bounds test
  passes after the test harness was given the Agility SDK exports.
- `victory-hle`: 98 passed.
- `victory-formats`: 25 passed, 4 ignored.
- `victory-shader`: 192 passed, 23 failed, 3 ignored. The failing hardware
  execution tests report that neither the physical adapter nor WARP exposes
  Shader Model 6.6 through the test feature query. This is an unresolved
  capability/runtime detection issue; those 23 cases are not counted as
  passing and were not disabled.
- Other workspace suites (core, game, loader, PE, pipeline and app tests)
  completed successfully.

The Release application itself builds and its `config` command reports
Agility SDK 620 at `target/release/D3D12/D3D12Core.dll`. A subsequent launch
check on this branch is recorded below.


## Updated branch launch check — 2026-11-25

A fresh Release build at `d65bdf2` was launched with the `balanced` profile.
VIctory loaded the Series X title, created the D3D12 device, translated
shaders, opened the `Americas` scene and reached a heavy world-rendering
workload. The process stayed responsive, but performance was far below
playable speed.

| Metric | Observed value |
|---|---:|
| Early scene display | 27–30 FPS |
| Heavy-world frame rate | 0.6–0.8 FPS |
| Heavy-world frame time | 1,243–1,609 ms |
| Peak observed draw calls | 2,989/frame |
| VIctory working set before stop | 6.19 GB |
| Free physical RAM before stop | 0.47 GB |
| Device removed / driver timeout | not observed |

The run was stopped manually when free RAM fell below 0.5 GB. Free RAM
recovered after the process exited. This confirms that the updated branch
reaches the heavy world scene on this PC; it does not establish playability.

The log showed two compute programs rejected by the shader converter:
`f133e35efed2a48a` (lane-mask exchange where not every lane runs) and
`926c46bab3b86bd6` (lane mask holding lanes elsewhere read as data). Several
compute pipeline creations were also refused with `0x80070057`. These remain
open shader/host-compatibility issues.

The shader lowering unit subset passed after the LDS and helper-quad changes:
17 passed, 0 failed, 1 ignored. The full GPU-backed shader suite is not green:
23 hardware tests failed because the test process did not expose the required
Shader Model 6.6 device capability; those failures were not suppressed.

## Indirect-window experiment

The launcher now provides two additional profiles:

- `indirect-window`: enables `VICTORY_INDIRECT_WINDOW=1`, grouping sequential
  indirect draws into clamped windows of up to 64 records.
- `indirect-window-check`: also enables `VICTORY_INDIRECT_WINDOW_CHECK=1`,
  re-clamping each draw served from a window and comparing the results. This
  is a correctness check, not a performance profile.

These profiles have been added for the next controlled test. No performance
improvement is claimed until the same world scene is measured with comparable
shader-cache and memory conditions.


## Indirect-window D3D12 microbenchmark — 2026-11-25

The built-in benchmark `indirect::bench::bench_indirect_draw_barriers` was
run twice on the NVIDIA GeForce RTX 3050. Each run warms up, then measures
9 frames per case and reports the median. Each frame records 3,200 one-record
indirect draws of tiny triangles; it does not load GTA VI or game assets.

| Case | Run 1 GPU ms | Run 2 GPU ms |
|---|---:|---:|
| One at a time, original clamp | 25.22 | 25.16 |
| One at a time, current clamp | 25.74 | 25.71 |
| Windows of 32, original clamp | 43.53 | 43.35 |
| Windows, original clamp with new barriers | 40.09 | 39.70 |
| Windows of 32, current clamp | 1.12 | 1.12 |
| One at a time, current clamp with GPU-resident budget | 21.54 | 21.57 |
| Windows of 32, current clamp with GPU-resident budget | 0.99 | 0.99 |

The current clamp with windows of 32 was about 97.4% lower GPU time than
the original clamp with windows of 32 (43.53/43.35 ms to 1.12 ms). Against
the original one-at-a-time case, it was about 95.6% lower (25.22/25.16 ms
to 1.12 ms). The result was repeatable in this microbenchmark. It is not a
measured GTA VI frame-rate gain: the benchmark uses small test draws, a
single synthetic command list and no title shaders, textures, memory traffic
or cross-queue waits. The next validation is to
capture a world scene where the title actually issues a long sequence of
indirect draws, then compare baseline and `indirect-window` at the same point.

The `indirect-window-check` game launch did not reach indirect draws before
memory pressure required the run to be stopped. Its window-check mode therefore
has not yet produced real-scene correctness counts.


## Real-scene indirect-window attempts — 2026-11-25

Two short game launches were made with `indirect-window-check` and
`indirect-window` respectively, using the explicit local `-GameExe` path.
Both reached the `Americas` window and the process remained responsive.
Neither run reached a title workload that issued indirect draws: the logs
continued to report 0 indirect executions and 0 indirect mesh dispatches,
with only 3–12 ordinary draws per frame. The runs were stopped as memory
pressure increased (free RAM reached 1.92 GB in the check run and 1.38 GB in
the non-check run). Therefore no real-scene correctness count or in-game
performance measurement exists for indirect windows yet.

The indirect-window microbenchmark and its correctness tests are positive
results, but must remain separate from the game's real-scene result until a
repeatable workload with non-zero indirect draws can be captured.

## Series S diagnostic run — 2026-11-25

The `0b0074e` upstream follow-up was applied on the local performance
branch. Its `plaincopy` tests passed (4 passed, 0 failed), and both the
Release application and the diagnostic application built successfully.
The launcher was extended to select `-BuildProfile diag`, `-Console series-s`
and the `indirect-window-copy` profile, which adds `VICTORY_COPY_PLAIN=1`
to the indirect-window profile.

A first diagnostic launch used:

- Build: `diag`, with frame logging and GPU-card telemetry.
- Console profile: Xbox Series S.
- Performance profile: `indirect-window`; plain-copy remained off.
- Hardware: Ryzen 5 5600, RTX 3050 8 GB, 16 GB system RAM, Windows 10.
- Game executable: the local Series X title build supplied by the user.

The title reached the `Americas` window and remained responsive, but this
was not a usable open-world benchmark. The window title reported around
28–30 FPS and 8–14 draws per frame. The host log repeatedly reported zero
indirect executions and zero indirect mesh dispatches. Thus the indirect
window switch had no indirect workload to optimize, and `VICTORY_COPY_PLAIN`
was not enabled in this run.

The title's frame interval was 33.333 ms. Ordinary menu frames were about
33 ms, while most periodic GPU summaries reported approximately 0.0 ms of
GPU work. The selected Series S profile was confirmed in the log, but the
display mode reported to the title still remained 3840×2160; this run does
not show that the Series S profile lowered the output resolution.

The diagnostic trace did expose CPU/resource stalls outside the steady menu
frames:

| Event | Frame time | Notable work |
|---|---:|---|
| At 88.5 s | 127 ms | render thread 62 ms; remapping 64.9 ms across 291 calls; 104 disk reads / 16.8 MB |
| At 89.6 s | 1,083 ms | submit calls 156.7 ms; recording 54.5 ms across all threads; 226 other GPU lists; 738 disk reads / 99.3 MB; GPU idle 1,043.7 ms |
| At 103.5 s | 170 ms | submit calls 148.6 ms; recording 28.3 ms; GPU idle 166.6 ms |
| At 105.1 s | 206 ms | recording 174.4 ms across 614 calls; copies 2.7 ms / 3.3 MB; 358 disk reads / 16.4 MB |
| At 109.9 s | 455 ms | recording 416.8 ms across 567 calls; submit calls 55.4 ms; copies 4.5 ms / 5.5 MB; GPU idle 445.2 ms |

At the end of the run the process had about 9.4 GB of private/committed
memory, of which about 5.8 GB was resident; the GPU reported about 3.0 GB in
use from a 7.27 GB budget. Free physical RAM fell to approximately 0.68 GB.
The process was deliberately terminated and free RAM recovered. The launcher
reported exit code 1 because of that manual termination; this was not a
reported D3D12 device-removal event.

This trace points to CPU-side command recording, submission, memory
remapping, resource uploads and disk reads as the main visible sources of
long stalls in this low-draw workload. It does not establish which of these
dominates in the open world. The current menu trace also shows very little
copy volume, so it cannot validate the potential `plaincopy` benefit.
Do not claim an FPS improvement from this run.

### Next controlled test

1. Reach the same gameplay checkpoint in both runs, not just the `Americas` window.
2. Use `-BuildProfile diag -Console series-s` for both runs.
3. First run `-Profile indirect-window`; then run `-Profile indirect-window-copy`.
4. Compare the same scene after shader/cache warm-up. Record draw calls, non-zero
   indirect counts, frame time, submit/recording time, in-place copy count/MB,
   GPU busy time and free system RAM.
5. Start only with at least 6 GB free physical RAM; stop before it approaches
   1 GB. Close memory-heavy applications only when it is safe to do so.

Log from this diagnostic pass is stored locally under `%TEMP%` as
`victory-indirect-window-20261125-160313.log`. The raw log is not committed
because it contains machine-specific paths and session details.

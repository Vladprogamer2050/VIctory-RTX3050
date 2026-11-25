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

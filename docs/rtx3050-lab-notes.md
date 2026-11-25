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
Agility SDK 620 at `target/release/D3D12/D3D12Core.dll`. No GTA VI launch
was performed as part of this update.

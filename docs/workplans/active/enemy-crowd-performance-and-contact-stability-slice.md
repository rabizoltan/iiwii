# Enemy Crowd Performance And Contact Stability Slice

## Status
- `active`

## Purpose
- Diagnose the current dense-pack enemy jitter and FPS drop using the new runtime counters and optional CSV logging.
- Replace the older rollback-era restart note with a current execution guide tied to the actual codebase.
- Narrow the next implementation slice based on measured evidence instead of broad performance speculation.

## Current Context
1. The earlier dense-scene enemy navigation performance pass is already closed in [completed/enemy-dense-scene-navigation-performance-slice.md](d:/Game/DEV/iiWii/iiwii/docs/workplans/completed/enemy-dense-scene-navigation-performance-slice.md).
2. The current repo baseline already includes:
   - far-vs-near goal selection
   - shared local-neighbor reuse
   - short-lived frontline-rank caching
   - repeated direction-penalty cleanup in `enemy_crowd_response.gd`
3. New observability is now available through the shared `F3` overlay and optional `user://enemy_nav_perf_log.csv` output.
4. The current problem report is narrower than the older broad perf slice:
   - enemies behind the front line, especially around the near crowd band, keep vibrating and trying to move
   - FPS drops when that blocked crowd churn becomes visible

## Scope
- Dense-pack enemy jitter and FPS drop diagnosis in `DemoMain`.
- Measurement of nav-step churn, goal-selection churn, crowd-query pressure, and stuck/rejection pressure.
- Validation of the currently suspected hotspots before any new optimization or behavior change lands.
- Producing the evidence needed to define the next narrow implementation slice.

## Out Of Scope
- Immediate broad AI redesign.
- Reopening the rejected nav-refresh timing experiments as-is.
- Combat feedback presentation work.
- Traversal, dodge, or new enemy archetype work.
- Treating this document itself as the final fix plan.

## Current Runtime Baseline
1. `APPROACH` still reads the current nav step every physics tick.
2. The near/far nav refresh split is currently:
   - `<= 3m`: `0.1s`
   - `> 3m`: `0.5s`
3. The shared `F3` overlay now shows:
   - nav-cache refresh vs reuse totals
   - nav resolve, next-step, and path-scan rates
   - goal-selection rate plus direct vs ring totals
   - far-goal and missing-distance totals
   - path-metric and `map_get_path` rates
   - nearby/local/frontline-rank query rates
   - stuck recovery and frontline rejection pressure rates
4. Optional logging now writes timestamped CSV rows to `user://enemy_nav_perf_log.csv`.
5. Each CSV row includes both wall-clock time and `runtime_sec` so separate repro runs can be compared by elapsed runtime.

## Current Suspected Hotspots
1. Nav cache vs nav resolve mismatch:
   - verify whether nav work is still effectively happening every physics tick even when reuse should dominate
2. Direct-chase branch usage:
   - verify whether far enemies are actually taking the cheaper direct path often enough
   - confirm whether `missing-dist` is high during dense repro runs
3. Rear-line rejection pressure:
   - verify whether non-frontline enemies in the near crowd band keep being rejected and pushed back into active movement churn
4. Stuck recovery churn:
   - verify whether blocked enemies repeatedly enter recovery instead of settling
5. Crowd-query pressure:
   - verify how much nearby/local/rank query volume rises during the FPS drop window

## Investigation Questions
1. During the visible FPS drop, is `nav resolve/s` still close to `next-step/s`, suggesting ineffective practical throttling?
2. Does `missing-dist total` rise during the repro, indicating the direct-chase branch is underused or fed incomplete request data?
3. Do `frontline rejects/s` and `stuck/s` climb together during the vibration case?
4. Are `nearby/local/rank queries/s` high enough to be a meaningful secondary bottleneck once the crowd compresses?
5. Is the main spike mostly nav/goal churn, mostly registry-scan pressure, or a feedback loop between both?

## Execution Order

### Step 1 - Capture Dense-Pack Repro
Status: `active`

Actions:
1. Open `DemoMain`.
2. Use the dense crowd fixture that reproduces the rear-line vibration case.
3. Open the `F3` overlay.
4. Enable `Enemy Nav Perf Log` when a longer comparison run is needed.

Exit gate:
- At least one clear repro run exists where the visible jitter and FPS drop are both present.

### Step 2 - Record Counter Behavior
Status: `active`

Actions:
1. Record the overlay values during the repro window.
2. Save one or more CSV-backed runs from `user://enemy_nav_perf_log.csv`.
3. Note the runtime moment where FPS visibly degrades.

Focus counters:
1. `Nav cache R/U`
2. `nav resolve/s`
3. `next-step/s`
4. `Goals/s`
5. `missing-dist total`
6. `map_get_path/s`
7. `Nearby/local/rank queries/s`
8. `Stuck/s`
9. `frontline rejects/s`

Exit gate:
- The repro has measurable runtime evidence, not only visual observation.

### Step 3 - Classify The Primary Driver
Status: `pending`

Actions:
1. Compare the values during normal movement vs dense blocked churn.
2. Identify which family rises hardest during the FPS drop:
   - nav resolve / nav step work
   - goal / path-query work
   - crowd-query pressure
   - stuck / rejection churn
3. Use the result to choose the next narrow fix slice.

Exit gate:
- One primary driver and one secondary driver are identified with evidence.

## Acceptance Checks
1. The current jitter/FPS issue can be reproduced in `DemoMain`.
2. The `F3` overlay exposes enough information to distinguish nav churn from query churn.
3. At least one CSV-backed run exists with usable `runtime_sec` comparisons.
4. The next implementation slice can be named narrowly from evidence, not from broad suspicion.

## Open Risks
1. The visible jitter may be a feedback loop rather than a single hotspot, so one counter family alone may not explain the whole drop.
2. Manual repro quality still matters; inconsistent crowd setup can make runs hard to compare.
3. The CSV log is session-cumulative unless the runtime is restarted, so comparisons should be grouped carefully.

## Next Step
- Capture one or more dense-pack repro runs with the current `F3` counters and `user://enemy_nav_perf_log.csv`, then use that evidence to open a new narrow implementation slice for the highest-confidence hotspot.

# Step 3 Execution Doc - Nav Radius and Layer Alignment

## Objective
Eliminate navigation/body mismatch issues that cause wall sticking and invalid narrow-space path attempts.

## Why this is next
- It is a low-complexity hotfix compared to goal-selection refactor.
- It stabilizes core locomotion assumptions that later tasks depend on.
- It should remain valid long-term (not expected to be reverted by later phases).

## Inputs
- Runtime script: `godot/scripts/gameplay/enemies/enemy_basic.gd`
- Enemy scene: `godot/scenes/gameplay/enemies/EnemyBasic.tscn`
- Nav architecture refs:
  - `docs/architecture/ai/enemy-ai-config-v1.md`
  - `docs/architecture/ai/enemy-ai-navigation-v1.md`

## Implementation Tasks (in order)
1. Read collider size from enemy body collision shape at runtime (or use exported canonical value).
2. Set `nav_agent.radius` from collider radius with a controlled multiplier (`~1.10..1.20`).
3. Remove fixed `nav_agent.navigation_layers = 1` hardcode from generic setup path.
4. Introduce explicit enemy nav size layer assignment (for now at least one deterministic value per enemy type).
5. Validate spawn/nav bootstrap places agent on valid nav map point.
6. Add debug output once at startup:
   - collider radius
   - nav agent radius
   - navigation layers

## Acceptance Gates
- Enemy no longer attempts paths obviously narrower than its body size.
- Corner entry behavior improves versus previous build.
- No regression in path acquisition (`has_navigation_path` remains stable when reachable).

## Verification Checklist
- Scene: `godot/scenes/testbeds/Testbed_CombatNav.tscn`
- Manual checks:
  - Spawn enemy near narrow corridor edges.
  - Observe whether pathing repeatedly presses into blocked wall.
  - Confirm `NavigationAgent3D` layer matches intended nav region size class.

## Risks
- If radius multiplier is too large, path availability drops aggressively.
- If layer assignment policy is wrong, enemies may lose valid traversal routes.

## Rollback Plan
- Keep previous hardcoded values in commit history for quick compare.
- If path availability collapses, reduce multiplier first before reverting layer logic.

## Exit Condition to Start Step 4
- Step 3 acceptance gates all pass in testbed.
- No new collision/nav bootstrap regressions observed.

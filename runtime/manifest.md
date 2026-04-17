# Antigravity Runtime Manifest & Loading Contract

## Priority Rules
AI context evaluation policy:
1. **[Highest] Project Local**: `projects/[ProjectName]/.agent/` directory
2. **[Medium] Runtime Active**: `runtime/active_rules|active_workflows|active_skills/` directories
3. **[Zero] Upstream**: `upstream/` is read-only reference 窶・never load directly

## Runtime Constraints
- Never load files from `upstream/` as prompt context.
- When rules conflict, Project Local always wins.
- Changes to `active_*` must only be made via `promote-runtime-assets.ps1`.

## Promotion Route
- upstream -> skills_library: handled by initial-setup.ps1
- skills_library -> active_*: handled by promote-runtime-assets.ps1 (manual execution only)
- Direct copy to active_* is prohibited

## Global to Project Local Demotion Criteria
1. **Stack-specific**: Contains instructions only applicable to a specific language or framework.
2. **Oversized**: Reads more like detailed technical guidance than a guardrail; consumes excessive tokens.
3. **Low usage frequency**: Only relevant to fewer than half of all active projects.

If any criterion is met, remove from `active_*` and place in `projects/[name]/.agent/skills/local/`.

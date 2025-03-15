# Synergy Script Manifest

This document tracks all essential scripts in the Synapse project after consolidation.

## Core Scripts

| Script | Purpose | Status |
|--------|---------|--------|
| synergy.sh | Main command hub for all operations | ACTIVE |
| auto-branch-checker.sh | Ensures development on feature branches | ACTIVE |
| install-deps.sh | Installs project dependencies | UTILITY |

## Legacy Scripts (Could Be Consolidated)

| Script | Purpose | Status |
|--------|---------|--------|
| scripts/claude-commands.sh | Simple Claude workflow commands | LEGACY |
| scripts/claude-api.sh | Claude AI integration functions | LEGACY |

## Removed Scripts

The following scripts were removed during consolidation as their functionality is now in synergy.sh:

- All scripts in scripts/archive/
- All scripts in scripts/workflow/
- scripts/save-session.sh
- scripts/setup-claude-shortcuts.sh
- start-claude-session.sh
- start-compact-watch.sh
- synapse.sh
- view-project-status.sh
- Various README.md files in script directories

## Future Consolidation

For complete consolidation:

1. Move any necessary functions from claude-commands.sh and claude-api.sh into synergy.sh
2. Update .clauderc to not source these scripts
3. Remove the remaining legacy scripts

## How to Use

All project workflow operations are now handled through the synergy.sh script:

```bash
# Start development
./synergy.sh start

# Save Claude compact summary
./synergy.sh compact

# Show project status
./synergy.sh status

# And much more - see help for details
./synergy.sh help
```
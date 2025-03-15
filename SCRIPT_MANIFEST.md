# Synergy Script Manifest

This document tracks all essential scripts in the Synapse project after complete consolidation.

## Core Scripts

| Script | Purpose | Status |
|--------|---------|--------|
| synergy.sh | Main command hub for all operations | ACTIVE |
| auto-branch-checker.sh | Ensures development on feature branches | ACTIVE |
| install-deps.sh | Installs project dependencies | UTILITY |

## Removed Scripts

The following scripts were removed during consolidation as their functionality is now in synergy.sh:

- All scripts in scripts/archive/
- All scripts in scripts/workflow/
- scripts/claude-commands.sh
- scripts/claude-api.sh
- scripts/save-session.sh
- scripts/setup-claude-shortcuts.sh
- start-claude-session.sh
- start-compact-watch.sh
- synapse.sh
- view-project-status.sh
- Various README.md files in script directories

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

## Complete Consolidation

The codebase has been fully consolidated:

1. All functionality is now in synergy.sh
2. The scripts directory has been removed completely
3. Only core scripts remain at the project root
4. All documentation has been centralized

This simplified structure makes the workflow more maintainable and easier to understand.
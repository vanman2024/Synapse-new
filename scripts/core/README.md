# Synergy Core Modules

This directory contains the core functionality modules for the Synergy workflow system.

## Modules

- **config.sh**: Central configuration and helper functions
  - Environment variables
  - File paths
  - Helper functions
  - Color codes

- **session.sh**: Session management functions
  - Starting development sessions
  - Ending and archiving sessions
  - Session status reporting
  - Session file cleanup

- **module.sh**: Module tracking functions
  - Module status updates
  - Focus tracking
  - Feature branch creation
  - Smart commit functionality

- **git-hooks.sh**: Git automation functions
  - Git hook setup and management
  - Auto-commit functionality
  - Pull request creation
  - Pre-commit and pre-push hook content

## Module Loading Order

The modules generally have the following dependencies:

```
config.sh <-- session.sh <-- module.sh <-- git-hooks.sh
```

Each module imports its dependencies using the `source` command.
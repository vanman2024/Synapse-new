# Synergy Script Architecture

This directory contains the modular components of the Synergy workflow system. The scripts have been reorganized to improve maintainability and extensibility.

## Directory Structure

```
/scripts/
  /core/              # Core functionality
    config.sh         # Central configuration and helper functions
    session.sh        # Session management functions
    module.sh         # Module tracking functions
    git-hooks.sh      # Git hook setup and automation
  /integrations/      # External system integrations
    airtable.sh       # Airtable integration (primary tracking)
    github.sh         # GitHub Projects integration (legacy)
    claude.sh         # Claude AI integration
  /workflow/          # Workflow verification and utilities
    check-docs.sh     # Verifies documentation integrity
```

## Module Dependencies

```
synergy.sh
  └── config.sh
      ├── session.sh 
      │   └── module.sh
      │       └── git-hooks.sh
      └── integrations/
          ├── airtable.sh
          ├── github.sh
          └── claude.sh
```

## Extending the System

To add new functionality:

1. **New Core Feature**: Add a new module to the `/core/` directory
2. **New Integration**: Add a new module to the `/integrations/` directory
3. **New Command**: Update the command handler in synergy.sh

Each module should:
- Start with `source` to import config.sh
- Define functions with descriptive names
- Be independently testable
- Follow the established error handling pattern

## Module Loader Design

Modules are loaded on-demand to improve performance:
- The main synergy.sh script only loads config.sh by default
- Other modules are loaded dynamically when needed based on the command
- This approach reduces memory usage and startup time

## Configuration

All configuration options should be defined in config.sh:
- Environmental variables
- File paths
- Color codes
- Helper functions

This ensures all modules have consistent access to the same configuration.
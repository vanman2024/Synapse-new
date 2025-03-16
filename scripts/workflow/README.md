# Synapse Workflow Scripts

This directory contains scripts that automate various aspects of the development workflow for the Synapse project.

## Documentation Management

- `check-docs.sh` - Checks for inconsistencies between documentation files (MODULE_TRACKER.md, DEVELOPMENT_ROADMAP.md, PROJECT_TRACKER.md)
  - Ensures completed modules are marked consistently across all documentation
  - Verifies that the current focus module is properly set
  - Creates logs of documentation inconsistencies
  - Run this periodically to ensure documentation stays in sync

## Usage

Documentation is automatically updated by the synergy.sh script when:
1. Starting a new development session
2. Marking modules as complete
3. Creating new feature branches

For manual checks, run:

```bash
# Check for inconsistencies in documentation
./scripts/workflow/check-docs.sh
```
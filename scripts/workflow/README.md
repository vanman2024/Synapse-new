# Workflow Scripts

This directory contains all scripts related to the Claude AI session management workflow.

## Script Overview

### Main Scripts
- `claude-start.sh` - Starts a Claude session with all tracking systems
- `auto-session-tracker.sh` - Updates SESSION.md with current activity
- `session-commands.sh` - Processes standardized workflow commands
- `session-summary.sh` - Generates comprehensive session summaries
- `new-feature.sh` - Creates feature branches with planning documents
- `setup-hooks.sh` - Installs git hooks for session tracking
- `test-cycle.sh` - Manages iterative testing and debugging cycles

### Usage

#### Session Tracking
```bash
./scripts/workflow/auto-session-tracker.sh
```
Automatically called by auto-commit.sh and git hooks to update SESSION.md.

#### Command Processing
```bash
./scripts/workflow/session-commands.sh @command:parameters
```
Available commands:
- `@focus:component` - Set current focus to component
- `@sprint:name,start,end` - Set sprint information
- `@todo:task` - Add a task to Next Tasks
- `@summary` - Generate session summary
- `@help` - Show available commands

#### Feature Management
```bash
./scripts/workflow/new-feature.sh feature-name "Feature description"
```
Creates a new feature branch and planning document.

#### Session Summary
```bash
./scripts/workflow/session-summary.sh [hours_ago]
```
Generates a summary of activity from the specified time period.

## Command Reference

| Command | Purpose | Usage |
|---------|---------|-------|
| `@focus` | Change current focus | `@focus:content-repository` |
| `@sprint` | Update sprint info | `@sprint:Sprint 1,2025-03-12,2025-03-26` |
| `@todo` | Add task to Next Tasks | `@todo:Implement user authentication` |
| `@summary` | Generate session summary | `@summary` |

## Testing and Debugging

```bash
# Run a test cycle for a component
./scripts/workflow/test-cycle.sh component-name cycle-number

# Example: First test cycle for content repository 
./scripts/workflow/test-cycle.sh content-repository 1

# Example: Follow-up test after fixes
./scripts/workflow/test-cycle.sh content-repository 2
```

## File Organization

The workflow system uses these key files:
- `SESSION.md` - Current project status and focus
- `.claude-autocommit.lock` - Process ID of auto-commit
- `docs/workflow/session-archives/` - Archived session activities
- `features/` - Feature planning documents
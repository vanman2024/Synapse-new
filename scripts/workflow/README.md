# Workflow Scripts

This directory contains all scripts related to the Claude AI session management workflow.

## Script Overview

### Main Scripts
- `auto-session-tracker.sh` - Updates SESSION.md with current activity
- `session-commands.sh` - Processes standardized workflow commands
- `session-summary.sh` - Generates comprehensive session summaries
- `new-feature.sh` - Creates feature branches with planning documents
- `setup-hooks.sh` - Installs git hooks for session tracking

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

## File Organization

The workflow system uses these key files:
- `SESSION.md` - Current project status and focus
- `.claude-autocommit.lock` - Process ID of auto-commit
- `docs/workflow/session-archives/` - Archived session activities
- `features/` - Feature planning documents
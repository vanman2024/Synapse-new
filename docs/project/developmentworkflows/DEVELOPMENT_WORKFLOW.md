# Development Workflow

This document explains the development workflow for the Synapse project.

## Overview

The development workflow is managed through scripts in `/scripts/development/workflows/` that help track project progress, manage Git operations, run tests, and more.

## Key Concepts

### Development Sessions

Development sessions are tracked in `SESSION.md` at the root of the project. This file maintains:

- Current session information
- Project status
- Active tasks
- Recent progress
- Key files and context

Older sessions are automatically archived to `/docs/development/workflows/session-archives/`.

### Workflow Scripts

The following scripts manage the development workflow:

- `start-session.sh` - Start a new development session
- `auto-commit.sh` - Automatic Git commit functionality
- `session-archive.sh` - Archive older development sessions
- `claude-start.sh` - Start a Claude session with development context
- `test-cycle.sh` - Run test cycles for components
- `verify-and-push.sh` - Verify and push changes to GitHub

## Common Workflows

### Starting a New Session

```bash
./scripts/development/workflows/start-session.sh
```

This updates SESSION.md with a new session header and displays key project information.

### Working with Claude

```bash
./scripts/development/workflows/claude-start.sh
```

This prepares a development session for Claude, including:
- Starting the auto-commit process
- Updating SESSION.md
- Providing context to Claude

### Testing and Deployment

```bash
# Run tests for a component
./scripts/development/workflows/test-cycle.sh component-name cycle-number

# Verify and push changes
./scripts/development/workflows/verify-and-push.sh component-name
```

## Session Archives

Older development sessions are automatically archived to maintain a manageable SESSION.md while preserving history:

```bash
# List all archived sessions
./scripts/development/workflows/session-archive.sh --list

# Retrieve a specific archived session
./scripts/development/workflows/session-archive.sh --retrieve=YYYYMMDD
```
# Synapse Scripts Organization

This directory contains scripts for the Synapse project, organized by purpose.

## Important Distinction

These scripts support two different but complementary systems:

1. **Development Workflow** - Tracks actual code changes and project progress
   - Uses `SESSION.md` and git history 
   - Focus on implementation, tasks, and milestones
   - See `/docs/workflow/GUIDE.md` for details

2. **Claude Conversation Tracking** - Records AI-assisted discussions
   - Uses compact summaries in `/sessions/claude/`
   - Focus on problem-solving and design decisions
   - See `/docs/claude/README.md` for details

## Directory Structure

- **`/scripts/workflow/`** - Development workflow scripts
  - Project session management
  - Git automation
  - Feature management
  - Testing and deployment
  
  - **`/scripts/workflow/claude/`** - Claude conversation scripts
    - `auto-compact-watch.sh` - Watch for and process compact summaries
    - `save-compact-simple.sh` - Manual method to save summaries

- **`/scripts/save-session.sh`** - Core functionality for saving compact summaries

## How to Use

### Development Workflow

To manage the development process:
```bash
# Start a development session
./scripts/workflow/start-session.sh

# Commit changes automatically
./scripts/workflow/auto-commit.sh
```

### Claude Compact Summaries

To save Claude's compact summaries:
```bash
# Start the auto-compact watcher (recommended)
./start-compact-watch.sh

# OR - Manually save a compact summary
./scripts/workflow/claude/save-compact-simple.sh
```

## Simplified Approach

The scripts system has been streamlined:
- Only essential scripts are maintained
- Clear separation between development and conversation tracking
- Single entry point for users via launcher scripts
- Deprecated scripts have been archived

For a comprehensive explanation of how these systems work together,
see the main documentation at `/docs/claude/README.md`.

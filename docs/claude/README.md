# Claude & Development: Understanding the Distinction

This document clarifies the important distinction between Claude session management and project development workflow in the Synapse project.

## Two Distinct but Complementary Systems

The Synapse project uses two separate but interrelated systems:

1. **Claude Session Management**
   - **Purpose**: Track and archive interactions with Claude AI
   - **Primary Files**: Compact summaries in `/sessions/claude/compact-YYYYMMDD.md`
   - **Scripts**: `/scripts/workflow/auto-compact-watch.sh`, `/scripts/workflow/save-compact-simple.sh`
   - **Focus**: Preserving our discussions, problem-solving approaches, and design decisions

2. **Development Workflow**
   - **Purpose**: Track actual project progress and code development
   - **Primary Files**: `SESSION.md` and code in the repository
   - **Scripts**: `/scripts/workflow/auto-commit.sh`, `/scripts/workflow/session-archive.sh`, etc.
   - **Focus**: Code changes, implementation details, task tracking, and project milestones

## Understanding The Difference

- **Claude Sessions** are about our _conversations_ with Claude
  - These capture how we discussed problems
  - They record design decisions and rationales
  - They preserve problem-solving approaches
  - They document the AI assistance process

- **Development Workflow** is about the actual _code and progress_
  - This tracks what code was written
  - It manages git commits and branches
  - It monitors project milestones and tasks
  - It focuses on implementation details

## How They Work Together

Both systems complement each other:

1. We use Claude to discuss, design, and problem-solve
2. Claude generates compact summaries of our discussions
3. These summaries are saved using the compact summary system
4. Meanwhile, actual code changes are tracked via the development workflow
5. Session files in `SESSION.md` track what was implemented
6. The compact summaries provide context on why and how decisions were made

## Quick Start

```bash
# Start a development session
./scripts/workflow/start-session.sh

# Start the compact summary watcher
./scripts/workflow/auto-compact-watch.sh
```

## Documentation Files

- [CLAUDE_WORKFLOW.md](./CLAUDE_WORKFLOW.md) - Guide to working with Claude
- [MODULE_TRACKER.md](./MODULE_TRACKER.md) - Track module development status
- [/workflow/GUIDE.md](../workflow/GUIDE.md) - Development workflow guide

## Project Status

See the root [SESSION.md](../../SESSION.md) file for current project status and development focus.
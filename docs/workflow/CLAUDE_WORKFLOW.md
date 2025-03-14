# Claude AI Development Workflow

This document explains how to use Claude AI effectively with this project, including our automated tracking, session management, and commit system.

## Overview

The Synapse development workflow includes:

1. **Session Management**: Each development session is assigned a unique ID for tracking
2. **Auto-commit**: Changes are committed automatically at regular intervals
3. **Session Tracking**: All activities are recorded in SESSION.md and session storage
4. **Continuity**: New sessions can access previous session data for context

## Getting Started with Claude

1. **Starting a Claude Session**
   ```bash
   cd /mnt/c/Users/user/SynapseProject/Synapse-new
   ./scripts/workflow/claude-start.sh
   ```
   
   This startup script:
   - Starts the auto-commit process (commits every 5 minutes)
   - Updates SESSION.md with today's date
   - Displays current project status and focus
   - Sets up git hooks if needed

2. **Session Tracking with Compaction and Archiving**
   
   The Synapse project provides two complementary ways to manage session history:
   
   **a) Compaction-based Summaries (Recommended):**
   - At the end of each session, run the session-end.sh script
   - Use Claude's `/compact` command to generate a concise summary
   - The summary is added to SESSION.md and stored in `docs/workflow/session-summaries/`
   - This approach preserves key context without excessive detail
   - Use this workflow:
     ```bash
     # At the end of your session:
     ./scripts/workflow/session-end.sh
     
     # Follow the instructions to:
     # 1. Use the /compact command in Claude
     # 2. Save the summary
     # 3. Run the script again with the saved file
     ./scripts/workflow/session-end.sh path/to/summary.txt
     ```
  
   **b) Full Session Archiving (Fallback Method):**
   - `SESSION.md` contains recent sessions (current + previous 2 sessions)
   - New sessions are added to the top of the file
   - Older sessions are automatically archived to `docs/workflow/session-archives/`
   - Archives are named `session-YYYYMMDD.md` and organized by date
   - Access archives with:
     ```bash
     # List all available archives
     ./scripts/workflow/session-archive.sh --list
     
     # Retrieve a specific archive by date
     ./scripts/workflow/session-archive.sh --retrieve=YYYYMMDD
     
     # Customize how many sessions to keep in SESSION.md
     ./scripts/workflow/session-archive.sh --keep=5
     ```
   - Archives are automatically tracked by git when created
   - The `claude-start.sh` script shows recent archives for continuity

3. **Context Review Process**
   At the beginning of each session, Claude will automatically perform a comprehensive context review:
   
   - **Session status** (from SESSION.md)
     - Current focus and priorities
     - Recent activity and progress
     - Planned next steps
   
   - **Project documentation**
     - Architecture documentation for system design
     - Project structure documentation for code organization
     - Feature-specific documentation
   
   - **Current implementation**
     - Relevant source files for context
     - Models and interfaces for the components being worked on
     - Test files to understand expected behavior
   
   - **Feature plans**
     - If working on a feature, review the corresponding feature plan
     - Implementation tasks and requirements
     - Dependencies and test plans
   
   This thorough review ensures Claude maintains complete context awareness throughout the development process.

## Automation Tools

### 1. Auto-Commit System
The `auto-commit.sh` script runs in the background and:
- Commits all changes every 5 minutes
- Updates SESSION.md with your recent activities
- Pushes changes to GitHub automatically
- Logs its activity to logs/system/auto-commit.log
- Intelligently detects change types (feature, fix, docs, test, refactor)
- Respects .autocommitignore patterns to exclude unwanted files

### 2. Session Tracking System
The `scripts/workflow/auto-session-tracker.sh` script:
- Updates SESSION.md with your latest activities
- Records which files you've been working on
- Updates branch information
- Maintains continuity between Claude sessions
- Archives older activities to prevent SESSION.md bloat
- Tracks sprint progress and calculates days remaining
- Uses icons and formatting for better readability
- Tracks metrics like lines added/removed

### 3. Command System
The `scripts/workflow/session-commands.sh` script:
- Processes standardized commands (prefixed with @)
- Updates SESSION.md with changes based on commands
- Provides a consistent interface for session management
- Supports commands like @focus, @sprint, @todo, @summary

### 4. Context Prioritization
The `scripts/workflow/claude-start.sh` script now:
- Analyzes current focus to find relevant files
- Presents recently modified files related to current tasks
- Shows sprint information if available
- Prioritizes context for more efficient session starts

### 5. Feature Development
The `scripts/workflow/new-feature.sh` script streamlines feature development:
```bash
./scripts/workflow/new-feature.sh feature-name "Feature description"
```
This creates:
- A new feature branch automatically
- A detailed feature plan file
- Updates SESSION.md with your new focus

### 6. Session Summary
The `scripts/workflow/session-summary.sh` script generates comprehensive session summaries:
```bash
./scripts/workflow/session-summary.sh [hours_ago]
```
This provides:
- Activity metrics for the session (commits, files changed, lines added/removed)
- A breakdown of work types (features, fixes, docs, etc.)
- Time estimates and focus analysis
- An overview of changed files and recent commits

### 7. Test Cycle System
The `scripts/workflow/test-cycle.sh` script manages iterative testing:
```bash
./scripts/workflow/test-cycle.sh component-name cycle-number
```
This enables:
- Automated testing with iteration tracking
- Systematic verification of components
- Generation of test reports
- Integration with SESSION.md tracking
- Structured debugging workflow

### 8. Verify and Push System
The `scripts/workflow/verify-and-push.sh` script ensures code quality before GitHub pushes:
```bash
./scripts/workflow/verify-and-push.sh [component]
```
This provides:
- Final verification before GitHub pushes
- Separation between local commits and remote pushes
- Protection against pushing broken code
- Integration with the test cycle system
- Documentation of push events in SESSION.md

### 9. Git Hooks
Installed automatically to ensure:
- SESSION.md is updated on every commit
- All changes are properly tracked
- Feature branches are managed correctly

## Project Status Tracking

The `SESSION.md` file maintains:

1. **Project Status**
   - Completed components
   - In-progress work
   - Next steps

2. **Focus Areas**
   - Current tasks being worked on
   - Last activity performed
   - Next tasks to tackle

3. **Code Context**
   - Last files modified
   - Branch status
   - Key file references

## Workflow Summary

1. **Start Session**: Run `./claude-start.sh`
2. **Create Features**: Use `./scripts/new-feature.sh`
3. **Automatic Tracking**: All changes tracked in SESSION.md
4. **Continuity**: Next Claude session picks up where you left off

## Common Commands

| Command | Purpose |
|---------|---------|
| `./claude-start.sh` | Start a Claude session with auto-commit |
| `./scripts/new-feature.sh feature-name "Description"` | Create a new feature branch |
| `./scripts/auto-commit.sh` | Manually start auto-commit (runs automatically) |
| `git branch --show-current` | Check which branch you're on |
| `cat SESSION.md` | View current project status |

## Recovery Process

If you need to restart or recover:

1. Pull latest changes
   ```bash
   git pull origin master
   ```

2. Run the startup script
   ```bash
   ./claude-start.sh
   ```

3. Claude will automatically continue where you left off by reading SESSION.md
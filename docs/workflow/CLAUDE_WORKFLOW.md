# Claude AI Development Workflow

This document explains how to use Claude AI effectively with this project, including our automated tracking and commit system.

## Getting Started with Claude

1. **Starting a Claude Session**
   ```bash
   cd /mnt/c/Users/user/SynapseProject/Synapse-new
   ./claude-start.sh
   ```
   
   This startup script:
   - Starts the auto-commit process (commits every 5 minutes)
   - Updates SESSION.md with today's date
   - Displays current project status and focus
   - Sets up git hooks if needed

2. **Session Tracking**
   - `SESSION.md` contains all current project status and focus
   - This file is automatically updated with each commit
   - No need to manually track progress between sessions

## Automation Tools

### 1. Auto-Commit System
The `auto-commit.sh` script runs in the background and:
- Commits all changes every 5 minutes
- Updates SESSION.md with your recent activities
- Pushes changes to GitHub automatically
- Logs its activity to logs/system/auto-commit.log

### 2. Session Tracking System
The `auto-session-tracker.sh` script:
- Updates SESSION.md with your latest activities
- Records which files you've been working on
- Updates branch information
- Maintains continuity between Claude sessions

### 3. Feature Development
The `new-feature.sh` script streamlines feature development:
```bash
./scripts/new-feature.sh feature-name "Feature description"
```
This creates:
- A new feature branch automatically
- A detailed feature plan file
- Updates SESSION.md with your new focus

### 4. Git Hooks
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
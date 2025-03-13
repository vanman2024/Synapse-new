# Synapse Project Development Guide

## Getting Started

1. **Start each Claude session** with the claude-start script:
   ```bash
   ./claude-start.sh
   ```
   This script will:
   - Start the auto-commit process
   - Update SESSION.md with today's date
   - Display current project status
   - Show your current focus areas

2. **All tracking is automated!** The following happens automatically:
   - SESSION.md is updated with each commit
   - Your code is committed to GitHub every 5 minutes
   - Git hooks ensure SESSION.md stays current

## Working with Features

To start work on a new feature:

```bash
./scripts/new-feature.sh feature-name "Description of the feature"
```

This creates:
- A new feature branch
- A feature plan file in the features/ directory
- Updates SESSION.md with your current focus

## Available Scripts

| Script | Description |
|--------|-------------|
| `./claude-start.sh` | Start a new Claude session with auto-commit |
| `./scripts/new-feature.sh` | Start a new feature branch with planning |
| `./scripts/auto-session-tracker.sh` | Update SESSION.md (runs automatically) |
| `./scripts/auto-commit.sh` | Commit code every 5 minutes (runs automatically) |
| `./scripts/setup-hooks.sh` | Install git hooks (runs automatically) |

## Project Structure

The key project files and directories are:

```
/
├── SESSION.md             # Current session info and project status
├── claude-start.sh        # Start script for Claude sessions
├── features/              # Feature planning documents
├── scripts/               # Automation scripts
└── src/                   # Source code
    ├── api/               # Express API routes & controllers
    ├── data-sources/      # Data source implementations (Airtable)
    ├── models/            # Data models & interfaces
    ├── repositories/      # Repository implementation
    ├── services/          # Business logic services
    └── utils/             # Helper utilities
```

## Next Steps

According to the project plan, the next priorities are:

1. Complete Content Repository implementation
2. Implement Content Controller and API routes
3. Build Text Overlay System 
4. Integrate Slack for Approval Workflow
5. Implement Distribution System with Make.com

## Recovery Process

If you need to recover or start a new session:

1. Pull the latest changes:
   ```bash
   git pull origin master
   ```

2. Run the Claude start script:
   ```bash
   ./claude-start.sh
   ```

3. Check SESSION.md for the current status and focus
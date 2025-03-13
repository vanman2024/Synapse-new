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
| `./scripts/workflow/claude-start.sh` | Start a new Claude session with auto-commit |
| `./scripts/workflow/new-feature.sh` | Start a new feature branch with planning |
| `./scripts/workflow/session-commands.sh` | Process workflow commands (@focus, @sprint, etc.) |
| `./scripts/workflow/session-summary.sh` | Generate session activity summaries |
| `./scripts/workflow/auto-session-tracker.sh` | Update SESSION.md (runs automatically) |
| `./scripts/auto-commit.sh` | Commit code every 5 minutes (runs automatically) |
| `./scripts/workflow/setup-hooks.sh` | Install git hooks (runs automatically) |

## Project Structure

The key project files and directories are:

```
/
├── SESSION.md             # Current session info and project status
├── features/              # Feature planning documents
├── scripts/               # Automation scripts
│   ├── auto-commit.sh     # Main auto-commit script
│   └── workflow/          # Claude workflow scripts
│       ├── claude-start.sh         # Main startup script
│       ├── auto-session-tracker.sh  # Updates SESSION.md
│       ├── new-feature.sh          # Feature branch creation
│       ├── session-commands.sh     # Command processor
│       ├── session-summary.sh      # Session summary generator
│       └── setup-hooks.sh          # Git hooks installation
├── docs/                  # Documentation
│   └── workflow/          # Workflow documentation
│       └── session-archives/  # Archived session activities
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
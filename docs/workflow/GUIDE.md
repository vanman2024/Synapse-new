# Synapse Project Development Guide

## Project Location
- Main project directory: `/mnt/c/Users/user/SynapseProject/Synapse-new` (Windows path: `C:\Users\user\SynapseProject\Synapse-new`)

## Getting Started

1. **Start each Claude session** with the claude-start script:
   ```bash
   ./start-claude-session.sh
   ```
   This script will:
   - Start the auto-commit process
   - Load project context and documentation
   - Update SESSION.md with today's date
   - Display current project status
   - Show your current focus areas

2. **All tracking is automated!** The following happens automatically:
   - SESSION.md is updated with each commit
   - Your code is committed to GitHub every 5 minutes
   - Git hooks ensure SESSION.md stays current
   - Session summaries are automatically saved when using `/compact`

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

## Project Status and Priorities

Current priorities, in order of importance:

1. **Complete Content Repository implementation** (high priority)
   - Implement basic CRUD operations
   - Add content-specific methods like findByStatus, findByType

2. **Implement Content Controller and API routes**
   - Create RESTful endpoints for content management
   - Implement validation and error handling

3. **Build Text Overlay System**
   - Integrate with Cloudinary for image processing
   - Implement text positioning and styling features

4. **Integrate Slack for Approval Workflow**
   - Set up notifications for content needing approval
   - Add approval/rejection commands via Slack

5. **Implement Distribution System with Make.com**
   - Design workflows for content distribution
   - Connect to social media platforms API

Other ongoing tasks:
- Test the session archiving system improvements
- Complete GitHub Projects integration (medium priority)
- Clean up TypeScript errors (ongoing)
- Update workflow documentation (as needed)

## Session Preparation

At the start of each session, Claude should:

1. **Review recent sessions**:
   ```
   ls -la /mnt/c/Users/user/SynapseProject/Synapse-new/sessions/claude/compact-*.md | sort -r | head -1
   ```
   ```
   cat /mnt/c/Users/user/SynapseProject/Synapse-new/sessions/claude/compact-*.md | sort -r | head -1
   ```

2. **Check workflow session archives**:
   ```
   /mnt/c/Users/user/SynapseProject/Synapse-new/scripts/workflow/session-archive.sh --list
   ```

3. **Examine project structure**:
   ```
   ls -la /mnt/c/Users/user/SynapseProject/Synapse-new/src
   ```

## Session End Workflow

When ending a session with Claude:

1. **Automated Method** (Recommended):
   - When using `./start-claude-session.sh` or `./scripts/claude/claude-with-autocompact.sh`
   - Simply run the `/compact` command in Claude
   - The summary will be automatically detected and saved
   - No manual copying/pasting needed

2. **Manual Method**:
   - If not using the automated tools, use:
     ```
     /mnt/c/Users/user/SynapseProject/Synapse-new/scripts/workflow/session-end.sh
     ```
   - This script will prompt you to paste the compact summary and properly archive it

## Key Project Areas

- **Source code**: `/mnt/c/Users/user/SynapseProject/Synapse-new/src`
- **Documentation**: `/mnt/c/Users/user/SynapseProject/Synapse-new/docs`
- **Scripts**: `/mnt/c/Users/user/SynapseProject/Synapse-new/scripts`
- **Session archives**: 
  - Claude sessions: `/mnt/c/Users/user/SynapseProject/Synapse-new/sessions/claude`
  - Workflow sessions: `/mnt/c/Users/user/SynapseProject/Synapse-new/docs/workflow/session-archives`

## Frequently Used Commands

- **Build project**:
  ```
  # TBD - Add project build command here
  ```

- **Run tests**:
  ```
  # TBD - Add test command here
  ```

- **Start application**:
  ```
  # TBD - Add start application command here
  ```

## Recovery Process

If you need to recover or start a new session:

1. Pull the latest changes:
   ```bash
   git pull origin master
   ```

2. Run the Claude start script:
   ```bash
   ./start-claude-session.sh
   ```

3. Check SESSION.md for the current status and focus
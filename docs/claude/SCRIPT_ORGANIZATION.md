# Script Organization

The Synapse project organizes scripts into several categories:

## Directory Structure

```
scripts/
├── workflow/            # Development workflow scripts
│   ├── claude-start.sh  # Start a development session
│   ├── session-archive.sh
│   ├── session-manager.sh
│   ├── session-commands.sh
│   └── ...
│
├── auto-compact.sh      # Claude session tracking
├── compact-claude.sh    # Claude session tracking
└── auto-commit.sh       # Git commit automation
```

## Script Categories

### Development Workflow Scripts (`/scripts/workflow/`)

These scripts manage the development process:

- `claude-start.sh` - Start a new development session
- `session-archive.sh` - Archive older development sessions
- `session-manager.sh` - Manage SESSION.md
- `test-cycle.sh` - Run test cycles
- `verify-and-push.sh` - Verify and push to GitHub

### Claude Session Scripts (in `/scripts/`)

These scripts track Claude AI conversations:

- `auto-compact.sh` - Automatically track Claude sessions with /compact
- `compact-claude.sh` - Manually invoke Claude with /compact

### Utility Scripts (in `/scripts/`)

Other utility scripts:

- `auto-commit.sh` - Automatic Git commits
- `ts-check.sh` - TypeScript checking
- `branch-manager.sh` - Git branch management

## Output Directories

The scripts write to different directories:

- Development sessions: 
  - `SESSION.md` (current sessions)
  - `docs/workflow/session-archives/` (archived sessions)

- Claude AI sessions:
  - `sessions/claude-session-YYYYMMDD.md` (daily sessions)
  - `sessions/sessions-YYYYMM.md` (monthly indexes)

## Documentation

For more information:

- `docs/workflow/SESSION_MANAGEMENT.md` - Documentation of session systems
- `sessions/README.md` - Claude session file documentation
- `scripts/README.md` - Script organization documentation
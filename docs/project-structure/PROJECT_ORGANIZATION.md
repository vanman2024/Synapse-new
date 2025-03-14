# Synapse Project Organization

This document outlines the organization of the Synapse project, particularly focusing on scripts and workflows.

## Directory Structure

```
/
├── scripts/                        # All scripts for the project
│   ├── workflow/                   # Project workflow scripts
│   │   ├── start-session.sh        # Start a development session
│   │   ├── auto-commit.sh          # Automatic Git commits
│   │   ├── session-archive.sh      # Archive older sessions
│   │   └── ...                     # Other workflow scripts
│   │
│   └── claude/                     # Claude session scripts
│       ├── auto-compact.sh         # Capture Claude sessions automatically
│       ├── compact-claude.sh       # Manually invoke Claude compact
│       ├── claude-start.sh         # Start a Claude session
│       └── save-compact.sh         # Save Claude summaries
│
├── sessions/                       # All session data
│   ├── claude/                     # Claude AI session files
│   │   ├── claude-session-*.md     # Daily Claude session files
│   │   ├── *sessionClaudetxt.txt   # Full Claude session logs
│   │   └── sessions-index.json     # Index of all Claude sessions
│   │
│   └── workflow/                   # Workflow session archives
│       └── session-*.md            # Archived development sessions
│
├── docs/                           # Documentation
│   ├── workflow/                   # Workflow documentation
│   │   ├── WORKFLOW.md             # Main workflow documentation
│   │   └── ...                     # Other workflow documentation
│   │
│   ├── claude/                     # Claude documentation
│   │   ├── SESSIONS.md             # Session management documentation
│   │   └── ...                     # Other Claude documentation
│   │
│   └── project-structure/          # Project structure documentation
│       └── PROJECT_ORGANIZATION.md # This file
│
└── SESSION.md                      # Current development session tracking
```

## Two Distinct Workflow Systems

The project has two separate but complementary workflow systems:

### 1. Project Workflow

**Purpose**: Track project progress, code changes, and development sessions

**Key Files**:
- `SESSION.md` - Current development session tracking
- `/sessions/workflow/` - Archived development sessions

**Key Scripts**:
- `/scripts/workflow/start-session.sh` - Start a development session
- `/scripts/workflow/auto-commit.sh` - Automatic Git commits
- `/scripts/workflow/session-archive.sh` - Archive older sessions

**Documentation**:
- `/docs/workflow/WORKFLOW.md` - Main documentation

### 2. Claude Session Management

**Purpose**: Capture and organize Claude AI conversation summaries

**Key Files**:
- `/sessions/claude/claude-session-YYYYMMDD.md` - Daily Claude sessions
- `/sessions/claude/sessions-YYYYMM.md` - Monthly session indexes
- `/sessions/claude/*.txt` - Full Claude session logs

**Key Scripts**:
- `/scripts/claude/auto-compact.sh` - Automatically capture sessions
- `/scripts/claude/compact-claude.sh` - Manually invoke Claude
- `/scripts/claude/claude-start.sh` - Start a Claude session
- `/scripts/claude/save-compact.sh` - Save existing summaries

**Documentation**:
- `/docs/claude/SESSIONS.md` - Main documentation

## Integration Between Systems

While these systems are separate, they work together:

1. **Project Workflow** maintains project progress tracking
2. **Claude Session Management** preserves the detailed AI conversations that contribute to that progress

This separation allows for:
- Clean project progress tracking without conversation clutter
- Complete preservation of all Claude conversations for reference
- Clear organization and documentation of both workflows
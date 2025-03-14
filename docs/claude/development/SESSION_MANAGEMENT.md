# Synapse Session Management System

The Synapse project uses two distinct but complementary session tracking systems:

## 1. Development Sessions (PROJECT PROGRESS)

**Purpose**: Track project development progress over time

**Key Files**:
- `SESSION.md` - Main file tracking up to 3 recent development sessions
- `docs/workflow/session-archives/session-YYYYMMDD.md` - Archive of older development sessions

**Scripts**:
- `/scripts/workflow/claude-start.sh` - Start a new development session
- `/scripts/workflow/session-archive.sh` - Archive older development sessions
- `/scripts/workflow/auto-session-tracker.sh` - Update SESSION.md automatically

**Usage**:
```bash
# Start a new development session
./scripts/workflow/claude-start.sh

# Manage session archives
./scripts/workflow/session-archive.sh --list
./scripts/workflow/session-archive.sh --retrieve=YYYYMMDD
```

## 2. Claude AI Sessions (CONVERSATION TRACKING)

**Purpose**: Track individual Claude AI conversations and their summaries

**Key Files**:
- `/sessions/claude-session-YYYYMMDD.md` - Consolidated daily sessions
- `/sessions/sessions-YYYYMM.md` - Monthly index of sessions
- `/sessions/sessions-index.json` - Database of all sessions

**Scripts**:
- `/scripts/auto-compact.sh` - Automatically capture Claude sessions with /compact command
- `/scripts/compact-claude.sh` - Manually invoke Claude with /compact command

**Usage**:
```bash
# Automatically track a Claude session
./scripts/auto-compact.sh

# Manually invoke Claude with compact support
./scripts/compact-claude.sh
```

## Understanding the Separation

It's important to understand the distinction between these two systems:

1. **Development Sessions** track what you're working on over time, preserving a high-level view of project progress.

2. **Claude AI Sessions** track the actual conversations with Claude, including the details of problem solving and implementation.

This separation allows you to:
- Keep a clean project progress record without cluttering it with conversation details
- Still preserve all Claude conversations for future reference
- Navigate both levels of information independently

## Usage Workflow

A typical workflow uses both systems:

1. Start a development session:
   ```
   ./scripts/workflow/claude-start.sh
   ```

2. Launch Claude with session tracking:
   ```
   ./scripts/auto-compact.sh
   ```

3. When finished with Claude, use `/compact` to generate a summary

4. The development session is updated in SESSION.md
   The Claude conversation is saved in `/sessions/claude-session-YYYYMMDD.md`

5. For future sessions, repeat this process. Old sessions are automatically archived.
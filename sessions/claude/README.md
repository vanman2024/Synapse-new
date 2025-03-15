# ⚠️ CLAUDE CONVERSATION SUMMARIES ONLY ⚠️

This directory contains ONLY conversation summaries from Claude - NOT project progress or code changes.

## 🔄 TWO COMPLETELY SEPARATE SYSTEMS

The Synapse project maintains TWO DISTINCT tracking systems:

### 1️⃣ THIS SYSTEM: CLAUDE CONVERSATIONS
- **Purpose**: Records our DISCUSSIONS with Claude AI
- **Content**: Design approaches, problem-solving, rationales
- **NOT FOR**: Code changes, tasks, project progress
- **Files**: `/sessions/claude/compact-YYYYMMDD.md`
- **Scripts**: `/scripts/workflow/claude/*`

### 2️⃣ DEVELOPMENT TRACKING SYSTEM
- **Purpose**: Tracks ACTUAL CODE CHANGES and PROJECT PROGRESS
- **Content**: Implementation details, tasks, milestones
- **NOT FOR**: Storing conversations or discussions
- **Files**: `SESSION.md` (at project root)
- **Scripts**: `/scripts/workflow/development/*`

## 📂 Directory Structure

- **`compact-YYYYMMDD.md`** - Daily summary files (conversations only)
- **`compact-watch/`** - Drop Claude summaries here for auto-processing
- **`processed/`** - Already processed summary files
  
## 🚀 Using the Compact Summary System

### Option 1: Auto-Watch (Recommended)

```bash
# Start the auto-watch system
./start-compact-watch.sh
```

When you use `/compact` in Claude:
1. Save the output to `sessions/claude/compact-watch/any-name.txt`
2. It's automatically processed and saved

### Option 2: Manual Save

```bash
# Manually save a compact summary
./scripts/workflow/claude/save-compact-simple.sh
```

## 👁️ Viewing Conversation Summaries

```bash
# Today's conversations
cat ./sessions/claude/compact-$(date +"%Y%m%d").md

# List all conversation files
ls -la ./compact-*.md
```

## 📚 How Conversations Help Development

These conversation summaries:
- Provide CONTEXT for code decisions
- Document APPROACHES considered
- Preserve PROBLEM-SOLVING methods
- Create REFERENCE materials

IMPORTANT: They DON'T track project progress - use `SESSION.md` for that!

See `/docs/claude/README.md` for how these systems work together.

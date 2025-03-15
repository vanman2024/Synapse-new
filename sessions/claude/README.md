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
- **`debug/`** - Debugging logs for troubleshooting

## 🚀 Using the Compact Summary System

The original automatic compact summary system has been deprecated.

### Manual Approach

For now, please use the following manual approach:

1. Copy important information from your conversation with Claude
2. Manually create a file in this directory with the format `compact-YYYYMMDD.md`
3. Add your summary with proper formatting
4. Consider including it in your git commits

Example file structure:
```markdown
# Claude Compact Summary - March 15, 2025

## Session at 10:15:30

This is a summary of what we discussed:
- Item 1: Description
- Item 2: Description

---

## Session at 14:22:05

Another summary section:
- Point A
- Point B
```

A new automated solution may be implemented in the future.

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

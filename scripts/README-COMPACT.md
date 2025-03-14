# Claude Compact Summary Feature

This README explains how to use the compact summary feature with Claude.

## Overview

The `/compact` command in Claude provides a way to summarize your conversation into a concise overview of key points. This is especially useful when a session has gone on for a long time and you need to preserve the most important information.

## How to Use

1. **Generate a compact summary:**
   - At the end of your Claude session, type: `/compact`
   - Claude will generate a summary of the conversation enclosed in `<summary>` tags

2. **Save the summary:**
   - Copy the entire summary (including the `<summary>` tags if present)
   - Save it to a text file, for example: `sessions/my-summary.txt`

3. **Process the summary:**
   - Run: `./scripts/save-compact.sh sessions/my-summary.txt`
   - This will create a nicely formatted summary file: `sessions/compact-YYYYMMDD.md`

## Benefits

- Preserves key information without storing the entire conversation
- Creates a concise record you can reference in the future
- Helps maintain continuity between development sessions
- Takes up minimal storage space

## Notes

- This feature is completely separate from the development workflow
- The script will automatically handle summaries with or without `<summary>` tags
- All summaries are stored in the `sessions/` directory with a date stamp
- You can manually edit the summary files if needed
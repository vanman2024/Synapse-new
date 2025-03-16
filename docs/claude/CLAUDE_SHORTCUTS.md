# Claude Command Shortcuts

This document describes the special commands available when using Claude in the Synapse project.

## Available Commands

| Command | Description | Usage |
|---------|-------------|-------|
| `/compact` | Save a compact summary of the conversation | `/compact` |
| `/help` | Get help with Claude commands | `/help` |

## Compact Command

The `/compact` command saves a compact summary of the current conversation to a daily summary file in the `sessions/claude` directory.

### How to use:

1. In your message to Claude, prepare a summary of the conversation between `<summary>` tags:
   ```
   <summary>
   Here's a summary of what we discussed:
   - Item 1: Description
   - Item 2: Description
   </summary>
   ```

2. Type `/compact` and send the message to Claude

3. The summary will be automatically extracted and saved to `sessions/claude/compact-YYYYMMDD.md` with a timestamp

### Features:

- Multiple summaries on the same day are appended to the same file with timestamps
- Summaries are automatically extracted from between `<summary>` tags
- If an active session is running, a note about the saved summary is added to SESSION.md

## Implementation

The compact functionality uses the `compact-helper.sh` script to process the content and save it to the appropriate file. This script is referenced in the `.clauderc` configuration file.

If you experience issues with the compact command, check:
1. That compact-helper.sh is executable (`chmod +x compact-helper.sh`)
2. That .clauderc points to the correct script path
3. Check debug logs in /tmp/compact-debug.log
# Claude Session Management

This directory contains Claude session summaries and logs for the Synapse project.

## Session File Types

This directory stores several types of session files:

1. **Compact Summaries**: `compact-YYYYMMDD.md`
   - Contains the output from Claude's `/compact` command
   - Summarizes a session's key information and decisions

2. **Session Archives**: 
   - `YYYYMMDD-session.json` - Full Claude session JSON files (if available)
   - `archives/YYYYMMDDsessionClaudetxt.txt` - Text versions of sessions

3. **Session Index**: `sessions-index.json`
   - JSON database of all sessions
   - Used for programmatic access to sessions

## Automatic Compact Detection

The easiest way to use Claude with automatic compact detection is:

```bash
./scripts/claude/claude-with-autocompact.sh
```

This script will:
1. Start Claude normally
2. Monitor for when you use the `/compact` command
3. Automatically extract and save the summary
4. Update both Claude archives and workflow archives
5. No manual copying or pasting needed!

When you use `/compact` in your Claude session, the system will:
- Automatically detect the summary output
- Save it to compact-YYYYMMDD.md
- Create archive files in both systems
- Update the session index

## Manual Session End Workflow

If you prefer to manually handle session end:

1. Run the `/compact` command in Claude to generate a summary
2. Use the session-end.sh script to properly archive the session:

```bash
./scripts/workflow/session-end.sh
```

This script will:
- Stop the auto-commit process
- Perform a final commit
- Prompt you to paste the compact summary output
- Save the summary to appropriate locations
- Update the session archives
- Update the session index

## Alternative Compact Handling

If you just want to save the compact output without ending the session:

```bash
./scripts/claude/claude-compact-handler.sh
```

Or if you saved the compact output to a file:

```bash
./scripts/claude/claude-compact-handler.sh path/to/summary-file.txt
```

## Scripts That Manage Sessions

Several scripts manage these session files:

1. **Session End**: `/scripts/workflow/session-end.sh`
   - Main script to properly end a Claude session
   - Integrates with the workflow archive system
   - Saves and indexes the compact summary

2. **Compact Handler**: `/scripts/claude/claude-compact-handler.sh`
   - Handles the output from the `/compact` command
   - Saves the summary without ending the session

3. **Auto Capture**: `/scripts/claude/auto-compact.sh`
   - Automatically monitors Claude for `/compact` commands
   - Captures the summary and saves it
   - Updates indexes and maintains session history

4. **Manual Capture**: `/scripts/claude/compact-claude.sh`
   - Manually invokes Claude with the `/compact` command
   - Otherwise functions the same as auto-compact.sh

## Integration with Workflow Archives

Claude sessions are now integrated with the project's workflow session tracking system:

- **Claude Archives**: Stored in `/sessions/claude/`
- **Workflow Archives**: Stored in `/docs/workflow/session-archives/`

When you end a session with `session-end.sh`, the summary is saved to both locations,
ensuring session history is properly preserved and accessible from both systems.

## Viewing Archived Sessions

To list all archived workflow sessions:

```bash
./scripts/workflow/session-archive.sh --list
```

To view a specific archived session:

```bash
./scripts/workflow/session-archive.sh --retrieve=YYYYMMDD
```
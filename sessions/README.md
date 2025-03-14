# Sessions Directory

This directory stores all session data for the Synapse project with a simple structure:

## Organization

- `/sessions/claude/` - Claude AI session files and summaries
  - Daily session files (claude-session-YYYYMMDD.md)
  - Raw session logs (.txt files)
  - Session indexes

- `/sessions/projects/` - Project development session archives
  - Archived development sessions
  - These are moved from SESSION.md when they get too old

## How Sessions Are Managed

1. **Claude Sessions**: Managed by scripts in `/scripts/claude-sessions/`
   - Created when you use the `/compact` command in Claude
   - Files are dated and indexed automatically

2. **Project Sessions**: Managed by scripts in `/scripts/project-workflow/`
   - Current session is always in SESSION.md
   - Older sessions are archived here automatically

## Documentation

For complete details on how session management works:
- Claude sessions: `/docs/claude-sessions/SESSIONS.md`
- Project workflow: `/docs/project-workflow/WORKFLOW.md`

# Claude AI Quick Reference

## Starting Each Session

```bash
cd /mnt/c/Users/user/SynapseProject/Synapse-new
./claude-start.sh
```

This single command:
- Starts auto-commit (5-minute intervals)
- Shows project status 
- Updates tracking files
- Prepares for development

## Key Files

- **SESSION.md**: Current project status and focus
- **claude-start.sh**: Main startup script
- **scripts/auto-commit.sh**: Automatic commit system
- **scripts/new-feature.sh**: Feature branch creator
- **.claude-autocommit.lock**: Process ID of running auto-commit
- **logs/system/auto-commit.log**: Log output from auto-commit process

## Creating Features

```bash
./scripts/new-feature.sh feature-name "Description"
```

## Automation Tools

| Tool | Purpose | Manual Action Required? |
|------|---------|------------------------|
| Auto-commit | 5-minute commits to GitHub | No - runs automatically |
| Session tracker | Updates SESSION.md | No - runs with each commit |
| Git hooks | Updates tracking on commits | No - runs automatically |
| claude-start.sh | Sets up each Claude session | Yes - run at start |

## Automated Tracking

All these are updated automatically:
- Current project status 
- Branch information
- Recently modified files
- Current focus and tasks

## Recovery

If you need to recover:
1. Navigate to project directory
2. Run `./claude-start.sh`
3. Claude will read SESSION.md for context

## Project Structure

```
/
├── SESSION.md             # Current session info
├── CLAUDE_WORKFLOW.md     # Detailed workflow guide
├── CLAUDE_README.md       # This quick reference
├── claude-start.sh        # Session startup script
├── scripts/               # Automation scripts
└── src/                   # Source code
```
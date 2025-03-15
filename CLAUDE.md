# Claude Automation Guidelines

## Automated Monitoring
- Claude should automatically check for staged files after code changes
- Claude should offer to run smart_commit when changes are ready for commit
- Claude should recommend review_changes before PR creation
- Claude should proactively check code quality when new files are created

## Key Commands To Run Automatically
```bash
# After code changes are made, run:
check

# When changes are ready to commit:
smart_commit

# Before creating a PR:
review_changes

# For new features:
feature feature-name
```

## Common Workflows
1. **New Feature Creation**: Automatically run `feature` command
2. **Code Quality**: Automatically run `check` after file changes
3. **Commit Creation**: Suggest `smart_commit` when files are staged
4. **PR Creation**: Suggest `review_changes` and `pr` after multiple commits

## Schedule
- Run code quality checks every 30 minutes of active development
- Suggest commits after 10+ lines of code changes
- Run full verification before any PR creation
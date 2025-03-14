# Claude Workflow Shortcuts

This document describes the simplified commands available for working with Claude in the development workflow.

## Setup

To install the shortcuts, run:

```bash
./scripts/setup-claude-shortcuts.sh
```

This will:
1. Add the commands to your shell configuration
2. Create a `.clauderc` file in the project root for quick loading

## Available Commands

### Git Workflow Commands

| Command | Description | Example |
|---------|-------------|---------|
| `feature <name>` | Create a new feature branch | `feature add-auth` |
| `check` | Run typecheck, lint, and build | `check` |
| `commit <type> <msg>` | Create a commit with proper format | `commit feat "Add login page"` |
| `pr <title>` | Create and push a PR | `pr "Add authentication system"` |
| `lintfix` | Create a branch for fixing lint issues | `lintfix` |
| `push` | Push with verification | `push` |

### Claude AI Integration Commands

| Command | Description | Example |
|---------|-------------|---------|
| `ask_claude <question>` | Ask Claude a question | `ask_claude "How should I implement auth?"` |
| `review_code <file>` | Have Claude review a file | `review_code src/auth/login.ts` |
| `smart_commit` | Generate a commit message with Claude | `git add . && smart_commit` |
| `review_changes` | Review branch changes with Claude | `review_changes` |
| `claude-help` | Show all available commands | `claude-help` |

## Commit Types

When using the `commit` command, use one of these types:

- `feat`: A new feature
- `fix`: A bug fix
- `docs`: Documentation only changes
- `style`: Changes that don't affect the meaning of the code (white-space, formatting, etc.)
- `refactor`: A code change that neither fixes a bug nor adds a feature
- `test`: Adding missing tests or correcting existing tests
- `chore`: Changes to the build process or auxiliary tools

## Workflow Example

Here's a typical workflow using these commands:

```bash
# Start a new feature
feature user-auth

# Make changes...

# Check if everything builds
check

# Commit your changes
commit feat "Add user authentication"

# Create more commits as needed...
commit style "Format authentication code"
commit test "Add tests for authentication"

# Push your changes with verification
push

# Create a pull request
pr "Add user authentication system"
```

## Temporary Usage

If you haven't run the setup script, you can temporarily load the commands in your current shell:

```bash
source scripts/claude-commands.sh
```

Or if you've already run the setup script:

```bash
source .clauderc
```
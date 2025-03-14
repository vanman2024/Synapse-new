#!/bin/bash

# Get the directory where this script is located
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
COMMANDS_PATH="$SCRIPT_DIR/claude-commands.sh"
REPO_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"

# Make the commands script executable
chmod +x "$COMMANDS_PATH"

# Check which shell the user is using
SHELL_TYPE=$(basename "$SHELL")
RC_FILE=""

if [ "$SHELL_TYPE" = "bash" ]; then
    RC_FILE="$HOME/.bashrc"
elif [ "$SHELL_TYPE" = "zsh" ]; then
    RC_FILE="$HOME/.zshrc"
else
    echo "Unsupported shell: $SHELL_TYPE. Please manually add the following line to your shell's RC file:"
    echo "source \"$COMMANDS_PATH\""
    exit 1
fi

# Check if the commands file is already sourced in the RC file
if grep -q "source \"$COMMANDS_PATH\"" "$RC_FILE"; then
    echo "Claude commands are already set up in $RC_FILE"
else
    # Add the source line to the RC file
    echo "" >> "$RC_FILE"
    echo "# Source Claude workflow commands" >> "$RC_FILE"
    echo "source \"$COMMANDS_PATH\"" >> "$RC_FILE"
    
    echo "Claude commands have been added to $RC_FILE"
    echo "To start using them, either restart your terminal or run:"
    echo "source \"$RC_FILE\""
fi

# Create a local alias file for direct usage in the project
ALIAS_FILE="$REPO_ROOT/.clauderc"
echo "source \"$COMMANDS_PATH\"" > "$ALIAS_FILE"

echo ""
echo "Setup complete! You can now use the following simplified commands:"
echo ""
echo "feature <name>      - Create a new feature branch"
echo "check               - Run typecheck, lint, and build"
echo "commit <type> <msg> - Create a commit with proper format"
echo "pr <title>          - Create and push a PR"
echo "lintfix             - Create a branch for fixing lint issues"
echo "push                - Push with verification"
echo "claude-help         - Show all available commands"
echo ""
echo "In this project directory, you can quickly load commands with:"
echo "source .clauderc"
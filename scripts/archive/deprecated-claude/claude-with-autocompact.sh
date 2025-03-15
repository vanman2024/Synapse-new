#!/bin/bash -e

# claude-with-autocompact.sh - Run Claude with automatic compact detection
# This script starts Claude and automatically detects and captures /compact output

# Enable debug mode
DEBUG=true

# Error logging function
log_error() {
  echo "❌ ERROR: $1" >&2
  if [ "$DEBUG" = true ]; then
    echo "Debug info: $2" >&2
    if [ -n "$3" ]; then
      echo "Command output: $3" >&2
    fi
  fi
}

# Success logging function
log_success() {
  echo "✅ $1"
}

# Info logging function
log_info() {
  echo "ℹ️ $1"
}

# Get script directory
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_DIR="$(cd "$SCRIPT_DIR/../.." && pwd)"
WORKFLOW_DIR="$REPO_DIR/scripts/workflow"
SESSIONS_DIR="$REPO_DIR/sessions/claude"
DATE=$(date +"%Y%m%d")
TIME=$(date +"%H%M%S")
FIFO_FILE="/tmp/claude-fifo-$$"
LOG_FILE="$SESSIONS_DIR/claude-session-$DATE-$TIME.log"
COMPACT_FILE="$SESSIONS_DIR/compact-$DATE.md"

# Make sure sessions directory exists
mkdir -p "$SESSIONS_DIR/archives" || {
  log_error "Failed to create sessions directory" "Directory: $SESSIONS_DIR/archives"
  exit 1
}

# Check if 'claude' command is available
if ! command -v claude &> /dev/null; then
  log_error "Claude command not found" "Make sure Claude CLI is installed and in your PATH"
  exit 1
fi

# Create a FIFO (named pipe) for capturing the output
if ! mkfifo "$FIFO_FILE" 2>/dev/null; then
  log_error "Failed to create FIFO pipe" "Path: $FIFO_FILE, may already exist or permission denied"
  # Try to remove existing FIFO if it exists
  [ -p "$FIFO_FILE" ] && rm -f "$FIFO_FILE" && mkfifo "$FIFO_FILE" || {
    log_error "Could not create FIFO pipe even after cleanup" "Path: $FIFO_FILE"
    exit 1
  }
fi

# Trap to clean up the FIFO on exit
trap 'rm -f "$FIFO_FILE"; log_info "Cleaning up resources..."; exit' INT TERM EXIT

log_info "Starting Claude with auto-compact detection..."
log_info "Use /compact in your Claude session as normal"
log_info "The system will automatically save the compact summary"
log_info "Press Ctrl+C to exit Claude"
echo ""
log_info "Debugging enabled: Will show detailed error messages"
echo ""

# Create a log directory for debugging
DEBUG_DIR="$SESSIONS_DIR/debug"
mkdir -p "$DEBUG_DIR" || log_error "Failed to create debug directory" "Path: $DEBUG_DIR"

# Debugging log
DEBUG_LOG="$DEBUG_DIR/autocompact-$DATE-$TIME.log"
echo "DEBUG LOG: $DATE $TIME" > "$DEBUG_LOG"
echo "FIFO: $FIFO_FILE" >> "$DEBUG_LOG"
echo "CLAUDE OUTPUT LOG: $LOG_FILE" >> "$DEBUG_LOG"

# Start background process to monitor the output for compact command
# We'll use a more sophisticated approach to catch the summary
log_info "Setting up monitoring for /compact output..."
{
  echo "Starting tee process to capture output" >> "$DEBUG_LOG"
  tee >(grep --line-buffered -A 500 -e "<summary>" | grep --line-buffered -B 500 -e "</summary>" > "$LOG_FILE") < "$FIFO_FILE" 2>> "$DEBUG_LOG"
  echo "tee process ended" >> "$DEBUG_LOG"
} &
TEE_PID=$!

# Run Claude and redirect its output to our FIFO
log_info "Starting Claude..."
{
  echo "Running Claude with output to FIFO" >> "$DEBUG_LOG"
  claude > "$FIFO_FILE" 2>> "$DEBUG_LOG" || log_error "Claude command failed" "Check $DEBUG_LOG for details"
  echo "Claude command ended" >> "$DEBUG_LOG"
}

# Wait a moment for any remaining output
log_info "Claude session ended, checking for /compact output..."
sleep 2

# Debug info
ls -l "$LOG_FILE" >> "$DEBUG_LOG" 2>&1
echo "LOG_FILE size: $(wc -l < "$LOG_FILE" 2>/dev/null || echo "0")" >> "$DEBUG_LOG"
echo "LOG_FILE content head:" >> "$DEBUG_LOG"
head -20 "$LOG_FILE" >> "$DEBUG_LOG" 2>&1

# Check if we found a compact summary
if grep -q "<summary>" "$LOG_FILE" 2>/dev/null; then
  log_success "Detected /compact output!"
  echo "Found <summary> tag" >> "$DEBUG_LOG"
  
  # Extract content between <summary> tags
  if ! sed -n '/<summary>/,/<\/summary>/p' "$LOG_FILE" | sed 's/<summary>//g' | sed 's/<\/summary>//g' > "$LOG_FILE.extract"; then
    log_error "Failed to extract summary content" "Check $DEBUG_LOG for details"
    echo "Extraction command failed" >> "$DEBUG_LOG"
    exit 1
  fi
  
  echo "Extracted content size: $(wc -l < "$LOG_FILE.extract" 2>/dev/null || echo "0")" >> "$DEBUG_LOG"
  
  # Create or append to the compact summary file
  log_info "Saving to compact summary file at $COMPACT_FILE"
  {
    if [ ! -f "$COMPACT_FILE" ]; then
      # First summary of the day - create the file with header
      echo "# Claude Compact Summary - $(date +"%B %d, %Y")" > "$COMPACT_FILE"
      echo "" >> "$COMPACT_FILE"
    else
      # Append a separator for additional summaries
      echo "" >> "$COMPACT_FILE"
      echo "---" >> "$COMPACT_FILE"
      echo "" >> "$COMPACT_FILE"
    fi
    
    # Add a timestamp for this summary
    echo "## Session at $(date +"%H:%M:%S")" >> "$COMPACT_FILE"
    echo "" >> "$COMPACT_FILE"
    
    # Append the summary content
    cat "$LOG_FILE.extract" >> "$COMPACT_FILE"
  } || {
    log_error "Failed to update compact summary file" "Path: $COMPACT_FILE"
    exit 1
  }
  
  log_success "Saved compact summary to $COMPACT_FILE"
  echo "Summary save complete" >> "$DEBUG_LOG"
  
  # Update the sessions index file
  SESSIONS_INDEX="$SESSIONS_DIR/sessions-index.json"
  
  # Create index file if it doesn't exist or is empty
  if [ ! -s "$SESSIONS_INDEX" ]; then
    echo '{"sessions":[]}' > "$SESSIONS_INDEX" || {
      log_error "Failed to create sessions index file" "Path: $SESSIONS_INDEX"
      exit 1
    }
  fi
  
  # Add the session to the index using jq if available, otherwise append to a log file
  if command -v jq >/dev/null 2>&1; then
    log_info "Updating sessions index using jq..."
    echo "Using jq to update index" >> "$DEBUG_LOG"
    TEMP_JSON=$(mktemp)
    if jq --arg date "$(date +"%Y-%m-%d")" \
       --arg time "$(date +"%H:%M")" \
       --arg file "compact-$DATE.md" \
       '.sessions += [{"date": $date, "time": $time, "compact": $file}]' \
       "$SESSIONS_INDEX" > "$TEMP_JSON" && mv "$TEMP_JSON" "$SESSIONS_INDEX"; then
      log_success "Updated sessions index JSON"
    else
      log_error "Failed to update sessions index with jq" "Check $DEBUG_LOG for details"
      echo "jq command failed" >> "$DEBUG_LOG"
    fi
  else
    log_info "jq not available, updating sessions log file instead"
    echo "$(date +"%Y-%m-%d %H:%M") - compact-$DATE.md" >> "$SESSIONS_DIR/sessions-log.txt" || {
      log_error "Failed to update sessions log file" "Path: $SESSIONS_DIR/sessions-log.txt"
    }
    log_success "Updated sessions log (jq not available)"
  fi
  
  # Run session-archive.sh to update the workflow archives 
  if [ -f "$WORKFLOW_DIR/session-archive.sh" ]; then
    log_info "Updating workflow session archives..."
    echo "Updating workflow archives" >> "$DEBUG_LOG"
    
    # Create a workflow archive with the compact summary
    WORKFLOW_ARCHIVE_DIR="$REPO_DIR/docs/workflow/session-archives"
    mkdir -p "$WORKFLOW_ARCHIVE_DIR" || {
      log_error "Failed to create workflow archive directory" "Path: $WORKFLOW_ARCHIVE_DIR"
      exit 1
    }
    WORKFLOW_ARCHIVE_FILE="$WORKFLOW_ARCHIVE_DIR/session-$DATE.md"
    
    # Only create if it doesn't exist
    if [ ! -f "$WORKFLOW_ARCHIVE_FILE" ]; then
      log_info "Creating workflow archive file..."
      {
        echo "# Archived Session: $(date +"%B %d, %Y")" > "$WORKFLOW_ARCHIVE_FILE"
        echo "" >> "$WORKFLOW_ARCHIVE_FILE"
        echo "## Session Summary" >> "$WORKFLOW_ARCHIVE_FILE"
        echo "" >> "$WORKFLOW_ARCHIVE_FILE"
        cat "$LOG_FILE.extract" >> "$WORKFLOW_ARCHIVE_FILE"
      } || {
        log_error "Failed to create workflow archive file" "Path: $WORKFLOW_ARCHIVE_FILE"
        exit 1
      }
      log_success "Created workflow archive at $WORKFLOW_ARCHIVE_FILE"
    else
      log_info "Workflow archive for today already exists at $WORKFLOW_ARCHIVE_FILE"
    fi
    
    # Run the workflow archive script
    log_info "Running session-archive.sh to update archives..."
    if ! bash "$WORKFLOW_DIR/session-archive.sh"; then
      log_error "Failed to run session-archive.sh" "Check for errors in that script"
    else
      log_success "Workflow archives updated successfully"
    fi
  else
    log_error "session-archive.sh not found" "Path: $WORKFLOW_DIR/session-archive.sh"
  fi
  
  # Clean up
  rm -f "$LOG_FILE.extract"
  
  echo ""
  log_info "Processing complete! Summary successfully saved."
  log_info "Don't forget to run session-end.sh if you want to completely end the session:"
  log_info "  ./scripts/workflow/session-end.sh"
else
  log_error "No /compact output detected in this session" "Check the debug log for details"
  echo "No <summary> tag found in LOG_FILE" >> "$DEBUG_LOG"
  echo "This could mean:" >> "$DEBUG_LOG"
  echo "1. You didn't use the /compact command" >> "$DEBUG_LOG"
  echo "2. Claude didn't generate a proper summary with <summary> tags" >> "$DEBUG_LOG"
  echo "3. The monitoring process failed to capture the output" >> "$DEBUG_LOG"
fi

# Clean up
log_info "Cleaning up temporary files..."
rm -f "$FIFO_FILE"

# Final status message
if [ -f "$COMPACT_FILE" ]; then
  log_success "Session processed successfully!"
  log_info "Debug log available at: $DEBUG_LOG"
else
  log_error "Session processing incomplete" "Check debug log for details: $DEBUG_LOG"
  exit 1
fi
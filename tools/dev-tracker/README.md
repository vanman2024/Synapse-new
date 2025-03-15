# Development Tracking with Airtable

This directory contains tools for tracking development progress in Airtable, completely separate from the main application.

## Setup

1. Create a new Airtable base with the following tables:
   - **Modules**: For tracking individual development modules
   - **Phases**: For tracking development phases
   - **Sessions**: For tracking development sessions

2. Update the `.env` file with your Airtable credentials:
   ```
   # Development Tracking (separate from application)
   DEV_AIRTABLE_PAT=your_personal_access_token
   DEV_AIRTABLE_BASE_ID=your_base_id
   DEV_AIRTABLE_MODULES_TABLE=Modules
   DEV_AIRTABLE_PHASES_TABLE=Phases
   DEV_AIRTABLE_SESSIONS_TABLE=Sessions
   ```

3. Run the setup script to initialize the tables with data from the Development Overview document:
   ```bash
   cd tools/dev-tracker
   node setup-airtable.js
   ```

## Integration with synergy.sh

Add the following function to `synergy.sh` to integrate with Airtable:

```bash
# Airtable integration
use_airtable() {
  AIRTABLE_SCRIPT="$REPO_DIR/tools/dev-tracker/synergy-airtable.sh"
  
  if [ ! -f "$AIRTABLE_SCRIPT" ]; then
    echo -e "${YELLOW}Airtable integration script not found. Skipping Airtable integration.${NC}"
    return 1
  fi
  
  "$AIRTABLE_SCRIPT" "$@"
}
```

Then update the relevant functions in `synergy.sh` to call the Airtable integration:

For `update_module()`:
```bash
# Update Airtable if integration is available
use_airtable update-module "$MODULE" "$STATUS"
```

For `end_session()`:
```bash
# Log session in Airtable if integration is available
use_airtable log-session "$SESSION_FILE"
```

## Commands

The integration script provides the following commands:

- `synergy-airtable.sh update-module <module-name> <status>` - Update module status (complete, in-progress, planned)
- `synergy-airtable.sh log-session <session-file>` - Log a session in Airtable
- `synergy-airtable.sh get-phase` - Get current phase information
- `synergy-airtable.sh get-module <module-name>` - Get module information
- `synergy-airtable.sh get-phase-modules <phase-number>` - Get modules for a phase
- `synergy-airtable.sh setup` - Set up Airtable tables

## Airtable Base Structure

### Modules Table
- Name (Single line text) - Name of the module
- Phase (Single line text) - Name of the phase
- Phase Number (Number) - Phase number
- Status (Single select) - Completed, In Progress, Planned
- Last Updated (Date) - Date last updated

### Phases Table
- Name (Single line text) - Name of the phase
- Number (Number) - Phase number
- Status (Single select) - Current, Completed, Planned

### Sessions Table
- Date (Date) - Date of the session
- Branch (Single line text) - Git branch
- Focus (Single line text) - Module focus
- Status (Single select) - Completed, Active
- Start Time (Single line text) - Time started
- End Time (Single line text) - Time ended
- Summary (Long text) - Session summary
- Commits (Long text) - JSON string of commits
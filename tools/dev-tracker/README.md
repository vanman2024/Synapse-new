# Development Tracking with Airtable

This directory contains tools for tracking development progress in Airtable, completely separate from the main application.

## Setup Instructions

1. **Set up Airtable Tables**:
   - Review the schema in `AIRTABLE_SCHEMA.md`
   - Create the 3 tables: Phases, Modules, and Sessions 
   - Add the fields as specified in the schema

2. **Import Data**:
   - Option 1: Use the Airtable UI to import the CSV files in the `csv` directory
   - Option 2: Run the import script: `node setup-airtable.js`

3. **Configure Environment Variables**:
   - Ensure your `.env` file has the correct Airtable credentials:
   ```
   DEV_AIRTABLE_PAT=your_personal_access_token
   DEV_AIRTABLE_BASE_ID=your_base_id
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

## CSV Files

The `csv` directory contains data ready to import:

- `phases.csv` - All development phases
- `modules.csv` - All modules from the Development Overview
- `sessions.csv` - Example development sessions

## API Integration

The `airtable-integration.js` file provides functions for:
- Updating module status
- Logging development sessions
- Querying phase and module information

## Troubleshooting

- If you get "Unknown field" errors, check that your table field names match exactly with the schema in AIRTABLE_SCHEMA.md
- For API rate limiting issues, your operations may be throttled, retry after a few seconds
- If you need to recreate the integration, delete all records in the tables and re-import using the CSVs
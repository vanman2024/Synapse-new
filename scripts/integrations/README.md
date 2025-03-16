# Synergy Integrations

This directory contains integration modules for connecting the Synergy workflow system with external services.

## Modules

- **airtable.sh**: Airtable Integration (Primary Tracking)
  - Module status updates in Airtable
  - Session logging in Airtable
  - Setup and configuration of Airtable tables
  - Connects to `tools/dev-tracker/synergy-airtable.sh`

- **github.sh**: GitHub Projects Integration (Legacy)
  - GitHub Projects configuration retrieval
  - Module status updates in GitHub Projects
  - Used as a fallback when Airtable is not configured

- **claude.sh**: Claude AI Integration
  - Starting Claude with project context
  - Saving Claude compact summaries
  - Compact watcher functionality
  - Claude output management

## Configuration Requirements

### Airtable Integration

Requires a `.env` file in the project root with:
```
DEV_AIRTABLE_PAT=pat_your_personal_access_token
DEV_AIRTABLE_BASE_ID=app_your_base_id
```

### GitHub Projects Integration

Configured in config.sh with:
```bash
GITHUB_ORG="organization_name"
GITHUB_REPO="repository_name"
GITHUB_PROJECT_NUMBER="project_number"
GITHUB_STATUS_FIELD_ID="field_id"
```

### Claude Integration

Requires the Claude CLI to be installed. Run `claude -h` for more information.
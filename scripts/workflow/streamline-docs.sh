#!/bin/bash

# streamline-docs.sh - Script to consolidate and streamline project documentation
# Creates a single source of truth for module tracking and generates other docs

# Get repository directory
REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && cd ../../ && pwd)"
MODULE_TRACKER="$REPO_DIR/docs/project/MODULE_TRACKER.md"
ROADMAP_FILE="$REPO_DIR/docs/project/DEVELOPMENT_ROADMAP.md"
PROJECT_TRACKER="$REPO_DIR/docs/project/PROJECT_TRACKER.md"
LOG_FILE="$REPO_DIR/logs/doc-streamline.log"

# Ensure log directory exists
mkdir -p "$REPO_DIR/logs"

# Colors for output
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

echo "===============================================" >> "$LOG_FILE"
echo "Documentation streamlining at $(date)" >> "$LOG_FILE"
echo "===============================================" >> "$LOG_FILE"

echo -e "${YELLOW}Starting documentation streamlining process...${NC}"

# 1. First check if MODULE_DATA.json exists - our single source of truth
MODULE_DATA="$REPO_DIR/docs/project/MODULE_DATA.json"

if [ ! -f "$MODULE_DATA" ]; then
  # Create it from MODULE_TRACKER.md by parsing the markdown tables
  echo -e "${YELLOW}Creating initial MODULE_DATA.json from existing documentation...${NC}"
  echo "{" > "$MODULE_DATA"
  echo "  \"modules\": [" >> "$MODULE_DATA"
  
  # Process Core Infrastructure Modules
  echo -e "${YELLOW}Processing Core Infrastructure modules...${NC}"
  sed -n '/## Core Infrastructure Modules/,/##/p' "$MODULE_TRACKER" | grep '|' | grep -v "Module \\|---" | while read -r line; do
    module=$(echo "$line" | sed -E 's/\| ([^|]+) \|.*/\1/g' | sed 's/^[ \t]*//;s/[ \t]*$//')
    status=$(echo "$line" | sed -E 's/.*\| ([^|]+) \|.*/\1/g' | sed 's/^[ \t]*//;s/[ \t]*$//')
    description=$(echo "$line" | awk -F '|' '{print $3}' | sed 's/^[ \t]*//;s/[ \t]*$//')
    priority=$(echo "$line" | awk -F '|' '{print $4}' | sed 's/^[ \t]*//;s/[ \t]*$//')
    
    # Convert status to standardized format
    if [[ "$status" == *"Completed"* ]]; then
      status_code="completed"
    elif [[ "$status" == *"In Progress"* ]]; then
      status_code="in-progress"
    else
      status_code="planned"
    fi
    
    echo "    {" >> "$MODULE_DATA"
    echo "      \"module\": \"$module\"," >> "$MODULE_DATA"
    echo "      \"category\": \"Core Infrastructure\"," >> "$MODULE_DATA"
    echo "      \"status\": \"$status_code\"," >> "$MODULE_DATA"
    echo "      \"description\": \"$description\"," >> "$MODULE_DATA"
    echo "      \"priority\": \"$priority\"" >> "$MODULE_DATA"
    echo "    }," >> "$MODULE_DATA"
  done

  # Process Content Generation Pipeline
  echo -e "${YELLOW}Processing Content Generation modules...${NC}"
  sed -n '/## Content Generation Pipeline/,/##/p' "$MODULE_TRACKER" | grep '|' | grep -v "Module \\|---" | while read -r line; do
    module=$(echo "$line" | sed -E 's/\| ([^|]+) \|.*/\1/g' | sed 's/^[ \t]*//;s/[ \t]*$//')
    status=$(echo "$line" | sed -E 's/.*\| ([^|]+) \|.*/\1/g' | sed 's/^[ \t]*//;s/[ \t]*$//')
    description=$(echo "$line" | awk -F '|' '{print $3}' | sed 's/^[ \t]*//;s/[ \t]*$//')
    priority=$(echo "$line" | awk -F '|' '{print $4}' | sed 's/^[ \t]*//;s/[ \t]*$//')
    
    # Convert status to standardized format
    if [[ "$status" == *"Completed"* ]]; then
      status_code="completed"
    elif [[ "$status" == *"In Progress"* ]]; then
      status_code="in-progress"
    else
      status_code="planned"
    fi
    
    echo "    {" >> "$MODULE_DATA"
    echo "      \"module\": \"$module\"," >> "$MODULE_DATA"
    echo "      \"category\": \"Content Generation\"," >> "$MODULE_DATA"
    echo "      \"status\": \"$status_code\"," >> "$MODULE_DATA"
    echo "      \"description\": \"$description\"," >> "$MODULE_DATA"
    echo "      \"priority\": \"$priority\"" >> "$MODULE_DATA"
    echo "    }," >> "$MODULE_DATA"
  done

  # Process API Layer
  echo -e "${YELLOW}Processing API Layer modules...${NC}"
  sed -n '/## API Layer/,/##/p' "$MODULE_TRACKER" | grep '|' | grep -v "Module \\|---" | while read -r line; do
    module=$(echo "$line" | sed -E 's/\| ([^|]+) \|.*/\1/g' | sed 's/^[ \t]*//;s/[ \t]*$//')
    status=$(echo "$line" | sed -E 's/.*\| ([^|]+) \|.*/\1/g' | sed 's/^[ \t]*//;s/[ \t]*$//')
    description=$(echo "$line" | awk -F '|' '{print $3}' | sed 's/^[ \t]*//;s/[ \t]*$//')
    priority=$(echo "$line" | awk -F '|' '{print $4}' | sed 's/^[ \t]*//;s/[ \t]*$//')
    
    # Convert status to standardized format
    if [[ "$status" == *"Completed"* ]]; then
      status_code="completed"
    elif [[ "$status" == *"In Progress"* ]]; then
      status_code="in-progress"
    else
      status_code="planned"
    fi
    
    # Add a trailing comma for all but the last entry
    echo "    {" >> "$MODULE_DATA"
    echo "      \"module\": \"$module\"," >> "$MODULE_DATA"
    echo "      \"category\": \"API Layer\"," >> "$MODULE_DATA"
    echo "      \"status\": \"$status_code\"," >> "$MODULE_DATA"
    echo "      \"description\": \"$description\"," >> "$MODULE_DATA"
    echo "      \"priority\": \"$priority\"" >> "$MODULE_DATA"
    echo "    }" >> "$MODULE_DATA"
  done
  
  # Close JSON structure
  echo "  ]," >> "$MODULE_DATA"
  
  # Add focus module from PROJECT_TRACKER
  FOCUS_MODULE=$(grep "Focus Module" "$PROJECT_TRACKER" 2>/dev/null | cut -d':' -f2 | awk '{$1=$1};1')
  echo "  \"focus\": \"$FOCUS_MODULE\"," >> "$MODULE_DATA"
  
  # Add current phase
  CURRENT_PHASE=$(grep -n "(Current)" "$ROADMAP_FILE" | cut -d':' -f2 | sed 's/^## Phase \([0-9]\+\).*/\1/g')
  echo "  \"currentPhase\": $CURRENT_PHASE," >> "$MODULE_DATA"
  
  # Add last updated timestamp
  echo "  \"lastUpdated\": \"$(date +"%Y-%m-%d %H:%M:%S")\"" >> "$MODULE_DATA"
  echo "}" >> "$MODULE_DATA"
  
  echo -e "${GREEN}✅ Created MODULE_DATA.json as the single source of truth${NC}"
  echo "Created MODULE_DATA.json as the single source of truth" >> "$LOG_FILE"
fi

# 2. Generate MODULE_TRACKER.md from MODULE_DATA.json
echo -e "${YELLOW}Generating MODULE_TRACKER.md from MODULE_DATA.json...${NC}"

# Create temp file
TEMP_FILE=$(mktemp)

# Start with header
cat > "$TEMP_FILE" << EOF
# Synapse Project Module Tracker

This document provides a high-level overview of the major modules in the Synapse project, their status, and development plans. It serves as a roadmap for development sessions with Claude.

*Note: This file is automatically generated from MODULE_DATA.json - do not edit directly.*

## Core Infrastructure Modules

| Module | Status | Description | Priority | Est. Completion |
|--------|--------|-------------|----------|----------------|
EOF

# Add Core Infrastructure modules
jq -r '.modules[] | select(.category == "Core Infrastructure") | "| " + .module + " | " + (if .status == "completed" then "✅ Completed" elif .status == "in-progress" then "🔄 In Progress" else "📝 Planned" end) + " | " + .description + " | " + .priority + " | " + (if .status == "completed" then "Completed" else "TBD" end) + " |"' "$MODULE_DATA" >> "$TEMP_FILE"

# Add Content Generation Pipeline modules
cat >> "$TEMP_FILE" << EOF

## Content Generation Pipeline

| Module | Status | Description | Priority | Est. Completion |
|--------|--------|-------------|----------|----------------|
EOF

jq -r '.modules[] | select(.category == "Content Generation") | "| " + .module + " | " + (if .status == "completed" then "✅ Completed" elif .status == "in-progress" then "🔄 In Progress" else "📝 Planned" end) + " | " + .description + " | " + .priority + " | " + (if .status == "completed" then "Completed" else "TBD" end) + " |"' "$MODULE_DATA" >> "$TEMP_FILE"

# Add API Layer modules
cat >> "$TEMP_FILE" << EOF

## API Layer

| Module | Status | Description | Priority | Est. Completion |
|--------|--------|-------------|----------|----------------|
EOF

jq -r '.modules[] | select(.category == "API Layer") | "| " + .module + " | " + (if .status == "completed" then "✅ Completed" elif .status == "in-progress" then "🔄 In Progress" else "📝 Planned" end) + " | " + .description + " | " + .priority + " | " + (if .status == "completed" then "Completed" else "TBD" end) + " |"' "$MODULE_DATA" >> "$TEMP_FILE"

# Add Current Focus section
FOCUS_MODULE=$(jq -r '.focus' "$MODULE_DATA")
cat >> "$TEMP_FILE" << EOF

## Development Schedule

### Current Focus ($(date '+%B %Y'))
- **$FOCUS_MODULE Implementation**
  - Complete implementation of core functionality
  - Write comprehensive tests
  - Update documentation and API endpoints
EOF

# Replace MODULE_TRACKER.md with our generated file
mv "$TEMP_FILE" "$MODULE_TRACKER"

echo -e "${GREEN}✅ Generated MODULE_TRACKER.md${NC}"
echo "Generated MODULE_TRACKER.md" >> "$LOG_FILE"

# 3. Generate DEVELOPMENT_ROADMAP.md from MODULE_DATA.json
echo -e "${YELLOW}Generating DEVELOPMENT_ROADMAP.md from MODULE_DATA.json...${NC}"

# Create temp file
TEMP_FILE=$(mktemp)

# Start with header
cat > "$TEMP_FILE" << EOF
# Synapse Development Roadmap

This document outlines the development roadmap for building out the Synapse application iteratively.

*Note: This file is automatically generated from MODULE_DATA.json - do not edit directly.*

## Current State

Synapse is an API service that:
- Manages brand information and styling 
- Manages job postings
- Generates content for job postings using AI
- Uses Airtable as a data backend
- Integrates with Cloudinary for image storage
- Integrates with OpenAI for content generation
EOF

# Add Phase 1 modules
cat >> "$TEMP_FILE" << EOF

## Phase 1: Foundation & Verification $(if [ "$(jq -r '.currentPhase' "$MODULE_DATA")" == "1" ]; then echo "(Current)"; else echo "(Completed)"; fi)

EOF

jq -r '.modules[] | select(.category == "Core Infrastructure") | "- [" + (if .status == "completed" then "x" else " " end) + "] " + .module + ": " + .description' "$MODULE_DATA" >> "$TEMP_FILE"

# Add Phase 2 modules
cat >> "$TEMP_FILE" << EOF

## Phase 2: Content Generation Enhancement $(if [ "$(jq -r '.currentPhase' "$MODULE_DATA")" == "2" ]; then echo "(Current)"; else echo ""; fi)

EOF

jq -r '.modules[] | select(.category == "Content Generation") | "- [" + (if .status == "completed" then "x" else " " end) + "] " + .module + ": " + .description' "$MODULE_DATA" >> "$TEMP_FILE"

# Add Phase 3 modules
cat >> "$TEMP_FILE" << EOF

## Phase 3: API & Integration $(if [ "$(jq -r '.currentPhase' "$MODULE_DATA")" == "3" ]; then echo "(Current)"; else echo ""; fi)

EOF

jq -r '.modules[] | select(.category == "API Layer") | "- [" + (if .status == "completed" then "x" else " " end) + "] " + .module + ": " + .description' "$MODULE_DATA" >> "$TEMP_FILE"

# Add Immediate Next Steps
FOCUS_MODULE=$(jq -r '.focus' "$MODULE_DATA")
cat >> "$TEMP_FILE" << EOF

## Immediate Next Steps

1. Complete implementation of $FOCUS_MODULE
2. Create comprehensive test suite for $FOCUS_MODULE
3. Update API documentation for new endpoints
4. Begin implementation of next prioritized module
5. Review and update project status documentation
EOF

# Add footer with generation info
cat >> "$TEMP_FILE" << EOF

---
*This document was automatically generated on $(date '+%Y-%m-%d') from the project's module data.*
EOF

# Replace DEVELOPMENT_ROADMAP.md with our generated file
mv "$TEMP_FILE" "$ROADMAP_FILE"

echo -e "${GREEN}✅ Generated DEVELOPMENT_ROADMAP.md${NC}"
echo "Generated DEVELOPMENT_ROADMAP.md" >> "$LOG_FILE"

# Final report
echo -e "${GREEN}Documentation streamlining completed!${NC}"
echo -e "${YELLOW}How to maintain documentation going forward:${NC}"
echo -e "1. Edit MODULE_DATA.json to update module status"
echo -e "2. Run this script to regenerate all documentation views"
echo -e "3. Use 'synergy.sh update-doc MODULE_NAME STATUS' to update in a single place"
echo -e "${GREEN}This approach ensures a single source of truth with multiple views.${NC}"

echo "Documentation streamlining completed at $(date)" >> "$LOG_FILE"
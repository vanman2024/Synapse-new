#!/bin/bash

# Script to run TypeScript validation and generate detailed error reports
# Usage: ./scripts/ts-check.sh

REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
ERROR_FILE="$REPO_DIR/typescript-errors.log"

# Ensure we're in the repo directory
cd "$REPO_DIR"

# Clear previous error file
echo "TypeScript Validation Report" > "$ERROR_FILE"
echo "Generated: $(date)" >> "$ERROR_FILE"
echo "----------------------------------------" >> "$ERROR_FILE"

echo "🔍 Running TypeScript validation..."

# Run TypeScript validation and capture output
npx tsc --noEmit --pretty false > "$ERROR_FILE.tmp" 2>&1

# Check if there are any errors
if grep -q "error TS" "$ERROR_FILE.tmp"; then
  echo "❌ TypeScript errors found"
  
  # Count total errors
  ERROR_COUNT=$(grep -c "error TS" "$ERROR_FILE.tmp")
  echo "   Found $ERROR_COUNT errors"
  
  # Extract and organize errors by file
  echo -e "\n== Errors by File ==" >> "$ERROR_FILE"
  grep -o -E "[^(]+\.[t|j]s[x]?:[0-9]+:[0-9]+" "$ERROR_FILE.tmp" | 
    sort | uniq -c | sort -nr >> "$ERROR_FILE"
  
  # Add the raw errors 
  echo -e "\n== Detailed Errors ==" >> "$ERROR_FILE"
  cat "$ERROR_FILE.tmp" >> "$ERROR_FILE"
  
  # Show most common error types
  echo -e "\n== Most Common Error Types ==" >> "$ERROR_FILE"
  grep -o -E "error TS[0-9]+" "$ERROR_FILE.tmp" | 
    sort | uniq -c | sort -nr >> "$ERROR_FILE"
  
  echo "📋 Complete error report saved to: typescript-errors.log"
  echo "   Run 'cat typescript-errors.log' to view or open in your editor"
  echo ""
  echo "🔝 Top errors:"
  head -n 10 "$ERROR_FILE.tmp" | grep "error TS"
else
  echo "✅ No TypeScript errors found!"
  echo "No TypeScript errors found!" >> "$ERROR_FILE"
fi

# Clean up
rm "$ERROR_FILE.tmp"

echo "----------------------------------------"
echo "Done!"
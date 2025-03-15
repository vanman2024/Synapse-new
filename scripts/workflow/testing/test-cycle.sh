#!/bin/bash

# test-cycle.sh - Manages code testing iterations for features
# Usage: ./scripts/workflow/test-cycle.sh [component] [cycle-number]

# Get the workflow directory
WORKFLOW_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# Get the repository root directory (two levels up from the workflow dir)
REPO_DIR="$(cd "$WORKFLOW_DIR/../.." && pwd)"
SESSION_FILE="$REPO_DIR/SESSION.md"
COMPONENT=$1
CYCLE=${2:-1}  # Default to cycle 1 if not specified

# Function to run appropriate tests based on component
run_tests() {
  local component=$1
  echo "Running tests for component: $component"
  
  # Check if component-specific tests exist, otherwise run general tests
  if [ -d "$REPO_DIR/tests/$component" ]; then
    echo "Found component-specific tests"
    TEST_CMD="npm test -- --testPathPattern=$component"
  else
    echo "Running general tests"
    TEST_CMD="npm test"
  fi
  
  # Run the tests
  cd "$REPO_DIR"
  $TEST_CMD
  TEST_STATUS=$?
  
  return $TEST_STATUS
}

# Function to run linting
run_lint() {
  echo "Running linting..."
  cd "$REPO_DIR"
  npm run lint
  return $?
}

# Function to run type checking
run_typecheck() {
  echo "Running type checking..."
  cd "$REPO_DIR"
  npm run typecheck
  return $?
}

# Create a test report
create_test_report() {
  local component=$1
  local cycle=$2
  local test_status=$3
  local lint_status=$4
  local typecheck_status=$5
  
  local report_dir="$REPO_DIR/logs/test-reports"
  mkdir -p "$report_dir"
  
  local timestamp=$(date +"%Y%m%d_%H%M%S")
  local report_file="$report_dir/${component}_cycle${cycle}_${timestamp}.md"
  
  # Create the report
  cat > "$report_file" << EOF
# Test Report: $component (Cycle $cycle)

## Test Information
- **Component**: $component
- **Cycle**: $cycle
- **Timestamp**: $(date +"%Y-%m-%d %H:%M:%S")
- **Branch**: $(git branch --show-current)

## Test Results
- **Unit Tests**: $([ $test_status -eq 0 ] && echo "✅ PASSED" || echo "❌ FAILED")
- **Linting**: $([ $lint_status -eq 0 ] && echo "✅ PASSED" || echo "❌ FAILED")
- **Type Checking**: $([ $typecheck_status -eq 0 ] && echo "✅ PASSED" || echo "❌ FAILED")

## Changes Tested
\`\`\`
$(git diff --stat HEAD~1)
\`\`\`

## Issues and Observations
- [ ] Add any issues found during testing
- [ ] Add observations about code behavior

## Next Iteration
- [ ] Document changes needed for next iteration

EOF

  echo "Test report created at: $report_file"
  cat "$report_file"
  
  # Update SESSION.md with test results
  update_session_with_test_results "$component" "$cycle" "$test_status" "$lint_status" "$typecheck_status"
}

# Update SESSION.md with test results
update_session_with_test_results() {
  local component=$1
  local cycle=$2
  local test_status=$3
  local lint_status=$4
  local typecheck_status=$5
  
  # Determine overall status
  if [ $test_status -eq 0 ] && [ $lint_status -eq 0 ] && [ $typecheck_status -eq 0 ]; then
    local overall_status="✅ PASSED"
  else
    local overall_status="❌ NEEDS FIXES"
  fi
  
  # Update Last Activity in SESSION.md
  local last_activity="🧪 **$(date +"%H:%M")** - Test Cycle $cycle for $component: $overall_status"
  
  # Use sed to insert after Last Activity section
  sed -i "/#### Last Activity/a $last_activity" "$SESSION_FILE"
  
  # Add SESSION.md to git
  git add "$SESSION_FILE"
  
  echo "Updated SESSION.md with test results"
}

# Main function
main() {
  echo "=========================================="
  echo "    TEST CYCLE $CYCLE: $COMPONENT"
  echo "=========================================="
  
  if [ -z "$COMPONENT" ]; then
    echo "Error: Component name required."
    echo "Usage: ./scripts/workflow/test-cycle.sh [component] [cycle-number]"
    exit 1
  fi
  
  # Record start time
  CYCLE_START=$(date +%s)
  
  # Run the test suite
  run_tests "$COMPONENT"
  TEST_STATUS=$?
  
  # Run linting
  run_lint
  LINT_STATUS=$?
  
  # Run type checking
  run_typecheck
  TYPECHECK_STATUS=$?
  
  # Record end time and calculate duration
  CYCLE_END=$(date +%s)
  DURATION=$((CYCLE_END - CYCLE_START))
  
  echo ""
  echo "Test cycle completed in $DURATION seconds."
  echo "Status: Tests ($([ $TEST_STATUS -eq 0 ] && echo "PASS" || echo "FAIL")), Lint ($([ $LINT_STATUS -eq 0 ] && echo "PASS" || echo "FAIL")), Types ($([ $TYPECHECK_STATUS -eq 0 ] && echo "PASS" || echo "FAIL"))"
  
  # Create test report
  create_test_report "$COMPONENT" "$CYCLE" "$TEST_STATUS" "$LINT_STATUS" "$TYPECHECK_STATUS"
  
  # Return non-zero if any check failed
  if [ $TEST_STATUS -ne 0 ] || [ $LINT_STATUS -ne 0 ] || [ $TYPECHECK_STATUS -ne 0 ]; then
    echo "One or more checks failed. See report for details."
    return 1
  fi
  
  echo "All checks passed!"
  return 0
}

# Execute main function
main "$@"
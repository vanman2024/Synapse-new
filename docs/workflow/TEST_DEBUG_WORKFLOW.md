# Test & Debug Workflow

This document outlines the iterative testing and debugging process for the Synapse project.

## Test-Driven Development Cycle

Our development process follows this iterative cycle:

1. **Feature Development** - Write the initial code for a feature
2. **Test Cycle** - Run tests, linting, and type checking
3. **Debug & Fix** - Address any issues found during testing
4. **Repeat** - Continue cycles until all tests pass
5. **Review & Merge** - Submit for review and merge to develop branch

## Using the Test Cycle Script

The `test-cycle.sh` script automates the testing process:

```bash
./scripts/workflow/test-cycle.sh [component] [cycle-number]
```

Example:
```bash
./scripts/workflow/test-cycle.sh content-repository 1
```

This script:
- Runs appropriate tests for the component
- Performs linting and type checking
- Generates a test report
- Updates SESSION.md with test results
- Tracks the iterative improvement process

## Test Reports

Test reports are stored in `logs/test-reports/` with this naming convention:
```
[component]_cycle[number]_[timestamp].md
```

Each report includes:
- Test results (pass/fail)
- Linting and type checking results
- Changes tested in this cycle
- Issues and observations
- Plans for the next iteration

## Debugging Workflow

When tests fail, follow this debugging workflow:

1. **Analyze Test Report** - Review the test report to understand failures
2. **Fix Issues** - Address the identified problems
3. **Run Next Cycle** - Run the next test cycle with incremented cycle number
   ```bash
   ./scripts/workflow/test-cycle.sh content-repository 2
   ```
4. **Document Progress** - Add notes about fixes to SESSION.md

## Integration with Session Tracking

The test cycle process is integrated with our session tracking system:

- Test results are automatically added to SESSION.md
- The cycle number is tracked across sessions
- Previous test reports are preserved for reference

## Example Workflow

```bash
# Start a feature branch for content repository
./scripts/workflow/new-feature.sh content-repository "Implement content repository"

# Develop initial implementation
# ... (code development) ...

# Run first test cycle
./scripts/workflow/test-cycle.sh content-repository 1

# Make fixes based on test results
# ... (fix code) ...

# Run second test cycle
./scripts/workflow/test-cycle.sh content-repository 2

# Continue until all tests pass
# ... (further cycles) ...

# When all tests pass, prepare for review
./scripts/workflow/session-commands.sh @todo:"Review and merge content repository"
```

## Best Practices

1. **Always Increment Cycle Number** - This maintains a clear history of iterations
2. **Document Test Observations** - Add detailed notes to test reports
3. **Commit After Each Cycle** - Ensure progress is saved even if interrupted
4. **Focus on One Component** - Test and debug one component at a time
5. **Update Next Tasks** - Keep SESSION.md updated with next debugging steps

## Automated Verification

The system automatically runs:
- **Unit tests** - Tests of individual functions and modules
- **Linting** - Code style and best practice checks
- **Type checking** - TypeScript type verification

You can add custom verification steps in the `test-cycle.sh` script as needed.
# Claude Development Instructions

This document serves as a reference guide for Claude when working on the Synapse project. It outlines development standards, processes, and communication protocols.

## Development Approach

### General Guidelines
- Follow test-driven development (TDD) practices
- Write modular, maintainable code
- Prioritize readability and documentation
- Apply SOLID principles and design patterns appropriately
- Focus on one component at a time until it's complete and tested

### Workflow Process
1. Start every session with `./scripts/workflow/claude-start.sh`
2. Make sure to open and access only the following codebase C:\Users\user\SynapseProject\Synapse-new for this project 
2. Review SESSION.md for context and current focus
3. Use feature branches for all new development
4. Implement code with accompanying tests
5. Run test cycles to verify functionality
6. Only push to GitHub after verification passes

## Automated Testing

### When to Initiate Testing
- After completing a logical component or feature
- Before significant refactoring
- After bug fixes
- Before pushing to GitHub
- At the end of development sessions

### How Testing Works
1. **Unit Tests**: Test individual functions and methods
2. **Integration Tests**: Test interaction between components
3. **End-to-End Tests**: Test complete workflows
4. **Test Cycles**: Use `./scripts/workflow/test-cycle.sh component-name cycle-number`

### Test Coverage Requirements
- 100% coverage for critical functionality
- Minimum 80% coverage for all other code
- Test both success and failure paths
- Include edge cases and boundary conditions

## Code Documentation

### Code Comments
- Add JSDoc/TSDoc comments for all functions and classes
- Explain "why" not just "what" when logic is complex
- Document assumptions and constraints
- Update comments when code changes

### System Documentation
- Maintain up-to-date documentation in the docs directory
- Document architecture decisions and design patterns
- Include diagrams for complex interactions
- Keep API documentation synchronized with code

## Claude-Specific Instructions

### Communication Protocol
- Use direct, specific language about what you're working on
- Explain technical decisions and trade-offs
- Highlight areas of uncertainty or where multiple approaches exist
- Ask for clarification when requirements are ambiguous

### Testing Responsibility
- Proactively suggest running tests after completing components
- Provide clear explanations of test results
- Diagnose and explain test failures in plain language
- Document test coverage and any gaps

### Development Continuity
- At the end of each session, update SESSION.md
- Leave clear notes about current state and next steps
- Ensure all local commits are made before ending session
- Highlight any incomplete work or known issues

## Project-Specific Guidelines

### Architecture Patterns
- Repository pattern for data access
- Service layer for business logic
- Controllers for API endpoints
- Dependency injection for testability

### Technology Stack
- TypeScript for type safety
- Express.js for API framework
- Airtable for data storage
- Bull for job processing
- Jest for testing

### Performance Considerations
- Optimize database queries
- Use caching where appropriate
- Implement pagination for large datasets
- Be mindful of memory usage in background processes

## Development Priorities

1. Maintainability and readability
2. Test coverage and quality
3. Performance and scalability
4. Feature completeness

Always favor clean, well-tested code over quick implementations. Quality is more important than quantity.

## Reference Material

To understand the project better, refer to:
- RECOVERY.md for project structure details
- docs/architecture/ for system design
- docs/workflow/ for development workflow
- SESSION.md for current status and focus
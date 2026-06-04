---
description: Update project documentation for developers and AI context
---

# Update Project Documentation Workflow

This workflow ensures project documentation stays synchronized with codebase changes and provides comprehensive context for both human developers and AI assistants.

## When to Use

- After adding new domains, entities, or use cases
- When modifying architecture patterns
- After significant refactoring
- When adding new dependencies or external services
- Before major releases
- When onboarding new team members

## Steps

### 1. Analyze Current Project Structure

```bash
# Explore project structure
find internal -type f -name "*.go" | head -20
find tests -type f -name "*_test.go" | head -10
go mod tidy && go list -m all | head -10
```

### 2. Scan for New Components

// turbo
```bash
# Find new domains
find internal -maxdepth 2 -type d -name "*domain*" | sort

# Find new use cases  
find internal -type d -name "*application*" | sort

# Find new CQRS ports
find internal -type f -path "*/ports/*" -name "*.go" | sort

# Check for new dependencies
grep -r "require (" go.mod
```

### 3. Update Developer Documentation

Update `docs/README-DEVELOPER.md`:

- **Architecture Overview**: Update layer structure if changed
- **Domain Model**: Add new entities, value objects, domain errors
- **Use Cases**: Document new application services
- **CQRS Ports**: Update command/query/validation port lists
- **Dependencies**: Add new external libraries
- **API Endpoints**: Update endpoint documentation
- **File Organization**: Reflect any structural changes

### 4. Update AI Context Documentation

Update `docs/README-AI-CONTEXT.md`:

- **Critical Context**: Update architecture principles and patterns
- **Domain Model**: Add new entities, value objects, relationships
- **Current Use Cases**: Document new use cases and their CQRS ports
- **File Organization Rules**: Update structure examples
- **Current Project State**: Update implemented vs TODO sections
- **Key Files**: Add important new files to understand
- **External Dependencies**: Update dependency list

### 5. Generate Architecture Diagram

// turbo
```bash
# Create ASCII architecture diagram if not exists
cat > docs/ARCHITECTURE.md << 'EOF'
# Architecture Overview

```
find internal -type d -name "*" | grep -E "(domain|application|infrastructure|interfaces)" | sort
```

## Layer Structure
```
cmd/
├── membership/main.go
internal/
├── config/           # Configuration
├── di/              # Dependency injection
├── handler/         # HTTP handlers
├── interfaces/      # External interfaces
└── membership/      # Business domain
    ├── domain/      # Pure business logic
    ├── application/ # Use cases
    └── infrastructure/ # External implementations
```

## CQRS Pattern
```
Domain/Ports:     Define interfaces (commands, queries, validation)
Application:       Use cases orchestrate via interfaces
Infrastructure:    Implement domain/application interfaces
```
EOF
```

### 6. Update Testing Documentation

// turbo
```bash
# Document test structure
cat > docs/TESTING.md << 'EOF'
# Testing Strategy

## Test Structure
```
tests/membership/
├── domain/           # Unit tests for business logic
├── application/      # Unit tests for use cases
├── infrastructure/   # Integration tests with real DB/APIs
└── interfaces/       # End-to-end tests
```

## Testing Standards
- Unit Tests: Fast, isolated, use mocks for outgoing ports
- Integration Tests: Real infrastructure only, NEVER mocks
- Test Naming: `Test_given_scenario_when_action_then_expected`
- Assertions: `github.com/stretchr/testify/assert`
EOF
```

### 7. Validate Documentation Accuracy

// turbo
```bash
# Check if all mentioned files exist
echo "Checking documentation accuracy..."

# Verify domain files mentioned in docs exist
if [ -d "internal/membership/domain/member" ]; then
    echo "✓ Member domain exists"
else
    echo "✗ Member domain missing - update docs"
fi

# Verify application files mentioned in docs exist
if [ -d "internal/membership/application/enroll_member" ]; then
    echo "✓ Enroll member use case exists"
else
    echo "✗ Enroll member use case missing - update docs"
fi

# Verify test structure matches docs
if [ -d "tests/membership/domain" ] && [ -d "tests/membership/application" ]; then
    echo "✓ Test structure matches documentation"
else
    echo "✗ Test structure mismatch - update docs"
fi
```

### 8. Update Main README

// turbo
```bash
# Ensure main README references detailed docs
if ! grep -q "docs/README-DEVELOPER.md" README.md; then
    echo "
## Documentation

- **Developer Guide**: See [docs/README-DEVELOPER.md](docs/README-DEVELOPER.md) for detailed development documentation
- **AI Context**: See [docs/README-AI-CONTEXT.md](docs/README-AI-CONTEXT.md) for AI assistant context
- **Architecture**: See [docs/ARCHITECTURE.md](docs/ARCHITECTURE.md) for architecture overview
- **Testing**: See [docs/TESTING.md](docs/TESTING.md) for testing strategy
" >> README.md
fi
```

### 9. Create Documentation Index

// turbo
```bash
# Create documentation index
cat > docs/INDEX.md << 'EOF'
# Documentation Index

## For Developers
- [Developer Guide](README-DEVELOPER.md) - Complete development guide
- [Architecture Overview](ARCHITECTURE.md) - System architecture and patterns
- [Testing Strategy](TESTING.md) - Testing approach and standards

## For AI Assistants
- [AI Context](README-AI-CONTEXT.md) - Critical context for AI development
- [Architecture Patterns](../.windsurf/rules/go-architecture-patterns.md) - Go architecture standards
- [Clean Code Standards](../.windsurf/rules/go-clean-code-standards.md) - Go coding standards

## Workflows
- [Update Documentation](../.windsurf/workflows/update-documentation.workflow.md) - This workflow
- [Full TDD Cycle](../.windsurf/workflows/full-tdd-cycle.md) - Test-driven development
- [Refactor Production Code](../.windsurf/workflows/refactor-production-code.workflow.md) - Code refactoring
EOF
```

### 10. Verify Documentation Completeness

// turbo
```bash
# Final verification
echo "Documentation update complete!"
echo "Files updated:"
echo "- docs/README-DEVELOPER.md"
echo "- docs/README-AI-CONTEXT.md" 
echo "- docs/ARCHITECTURE.md"
echo "- docs/TESTING.md"
echo "- docs/INDEX.md"
echo "- README.md (if needed)"
echo ""
echo "Next steps:"
echo "1. Review updated documentation for accuracy"
echo "2. Test any new commands or workflows mentioned"
echo "3. Commit documentation changes"
echo "4. Share with team for review"
```

## Quality Checklist

Before completing the workflow, verify:

- [ ] All new domains/entities are documented
- [ ] All use cases and their CQRS ports are listed
- [ ] File structure examples match actual codebase
- [ ] Dependencies are up-to-date
- [ ] Architecture diagrams reflect current state
- [ ] Testing documentation matches actual test structure
- [ ] All referenced files exist
- [ ] Documentation is consistent across all files
- [ ] Main README references detailed documentation
- [ ] Documentation index is complete

## Maintenance

Run this workflow:
- **Weekly**: For active development teams
- **Before releases**: To ensure documentation is current
- **After major refactors**: To reflect architectural changes
- **When onboarding**: To prepare for new team members

## Automation

Consider setting up:
- Pre-commit hooks to check documentation accuracy
- CI jobs to validate documentation completeness
- Automated documentation generation from code comments
- Documentation coverage reports

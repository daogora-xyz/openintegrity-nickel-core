# Research Documentation

This directory contains curated content that inspires features and design decisions in openintegrity-nickel-core.

## Purpose

When you discover interesting concepts, articles, or implementations that could inform this project:

1. **Save the content** as a markdown file here
2. **Add context** explaining what inspired you
3. **Link to features** that resulted from the research

## Organization

```
docs/research/
├── README.md                    # This file
├── kiro-specs/
│   ├── overview.md              # Kiro Specs system overview
│   ├── tdd-tracking.md          # RED-GREEN-REFACTOR implementation
│   └── tasks-md-format.md       # tasks.md structure analysis
├── nickel-language/
│   ├── contracts.md             # Contract system capabilities
│   ├── record-contracts.md      # Schema enforcement patterns
│   └── export-formats.md        # JSON/YAML/TOML export
├── spec-driven-development/
│   ├── spec-kit.md              # GitHub spec-kit approach
│   ├── tessl.md                 # Tessl framework concepts
│   └── comparison.md            # SDD tool comparison
├── architecture-decisions/
│   ├── adr-format.md            # ADR structure and templates
│   ├── tools.md                 # adr-tools, log4brains, etc.
│   └── integration.md           # ADR integration with workflows
├── cryptographic-verification/
│   ├── sigstore-gitsign.md      # Keyless signing for CI/CD
│   ├── commit-chains.md         # Git commit hash dependencies
│   └── ssh-vs-gpg.md            # Signature format comparison
└── living-documentation/
    ├── gherkin-bdd.md           # BDD test documentation
    ├── doc-as-code.md           # Documentation generation
    └── ci-pipelines.md          # Automated doc updates
```

## Template for New Research

When adding new research, use this template:

````markdown
# [Topic Name]

**Source**: [URL or reference]
**Date Discovered**: YYYY-MM-DD
**Relevance**: [Brief statement of why this matters to the project]

## Summary

[2-3 paragraph overview of the concept/tool/approach]

## Key Insights

- **Insight 1**: [What we learned]
- **Insight 2**: [What surprised us]
- **Insight 3**: [What could be applied here]

## Potential Applications

### In openintegrity-nickel-core

1. **Feature X**: How this research could inform feature design
2. **Schema Y**: Specific contract patterns we could adopt
3. **Validation Z**: Verification approaches to explore

## Code Examples

```nickel
// Example showing how concept translates to Nickel
{
  example | ContractType = value,
}
```

## Related Research

- [Link to other research docs that connect]
- [Cross-references to implemented features]

## Open Questions

- [ ] Question 1: What we still need to figure out
- [ ] Question 2: Experiments to run
- [ ] Question 3: Community feedback to seek

## References

- [Primary source]
- [Related articles]
- [Tool documentation]
````

## Research Workflow

### 1. Discovery

When you find something interesting:

```bash
# Create a new research file
touch docs/research/[category]/[topic].md

# Use the template above
# Add content explaining what you found
```

### 2. Analysis

As you explore the concept:

- Extract key insights
- Identify potential applications
- Note open questions
- Link to related research

### 3. Implementation

When research leads to features:

- Reference the research doc in commit messages
- Link from feature docs back to research
- Update research doc with "Implemented in:" section

### 4. Iteration

Continuously refine research docs:

- Add new insights as understanding deepens
- Document what worked vs what didn't
- Update cross-references as project evolves

## Example Research Progression

### Step 1: Initial Discovery

```markdown
# Kiro Specs TDD Tracking

**Source**: https://kiro.dev/docs/specs/
**Date Discovered**: 2025-10-21
**Relevance**: Shows how to track RED-GREEN-REFACTOR in tasks.md

## Summary

Kiro consistently applies TDD cycle across all development stages...
```

### Step 2: Deep Dive

Add code examples, analyze structure, identify patterns

### Step 3: Application Design

```markdown
## Potential Applications

### In openintegrity-nickel-core

1. **TDD Phase Contracts**: Create Nickel contracts enforcing phase progression
   ```nickel
   {
     tdd_phase | [| 'red, 'green, 'refactor |],
     red_commit | String,
     green_commit | String,
   }
   ```
```

### Step 4: Implementation

```markdown
## Implementation Status

✅ **Implemented in**: `nickel/schemas/test-specs.ncl`
✅ **Commit**: abc123def
✅ **Feature**: TDD phase tracking with cryptographic verification
```

## Guidelines

### DO

✅ Save complete context (URLs, dates, quotes)
✅ Explain why research is relevant
✅ Update as understanding evolves
✅ Link to implementations
✅ Acknowledge sources properly

### DON'T

❌ Copy-paste without attribution
❌ Let research docs become stale
❌ Forget to link implementations back
❌ Save research without explaining relevance
❌ Skip the analysis/application sections

## Current Research Areas

### Active

- [ ] Nickel contract patterns for schemas
- [ ] TDD workflow cryptographic verification
- [ ] Format conversion strategies
- [ ] Living documentation generation

### Completed

- [x] Kiro Specs TDD tracking
- [x] spec-kit spec-first approach
- [x] Nickel language capabilities

### Backlog

- [ ] BDD test documentation with Gherkin
- [ ] CI/CD traceability patterns
- [ ] Schema versioning strategies
- [ ] Migration tooling approaches

## Contributing Research

If you find research that could benefit the project:

1. Create a markdown file in appropriate category
2. Use the template above
3. Commit with descriptive message
4. Cross-reference in relevant schema/doc files

## Questions?

Open an issue with tag `research` to discuss:

- Whether to add a new research category
- How to organize related findings
- Connections between research areas

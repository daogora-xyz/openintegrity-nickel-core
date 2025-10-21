# Kiro Specs

**Source**: https://kiro.dev/docs/specs/
**Date Discovered**: 2025-10-21
**Relevance**: Demonstrates spec-driven development with TDD tracking - directly applicable to work stream integrity concepts

## Summary

Kiro Specs is a specification-driven development system that formalizes the development process through structured artifacts. It creates a three-phase workflow (Requirements → Design → Implementation) where specs become the source of truth for both humans and AI.

The key innovation relevant to OpenIntegrity work streams: **Kiro consistently applies the RED-GREEN-REFACTOR TDD cycle across all development stages**, tracking test-driven development cryptographically via tasks.md.

## Key Features

### 1. Three-Phase Workflow

- **requirements.md**: User stories in EARS notation (Event-driven, Actionable, Realistic, Specific)
- **design.md**: Technical architecture, sequence diagrams, implementation considerations
- **tasks.md**: Implementation plan with TDD tracking

### 2. TDD Integration (RED-GREEN-REFACTOR)

Kiro's tasks.md tracks:
- **RED phase**: Test written before implementation (commit hash)
- **GREEN phase**: Test passes after implementation (commit hash)
- **REFACTOR phase**: Code optimization with passing tests (commit hashes)

This provides cryptographic proof of test-first development via git commit history.

### 3. Spec-as-Source-of-Truth

Specs are "living artifacts" that:
- Describe what the program should do
- Generate implementation guidance
- Track progress through discrete tasks
- Enable collaboration between product and engineering

## Insights for OpenIntegrity

### What We Learned

1. **Specs can be executable**: Not just documentation, but validation targets
2. **TDD can be tracked cryptographically**: Using git commit hashes to prove test-first workflow
3. **Three phases work well**: Requirements → Design → Implementation matches work stream stages
4. **Tasks need both forms**: Imperative ("Run tests") and continuous ("Running tests")

### What Surprised Us

- TDD tracking is built-in, not an afterthought
- EARS notation makes requirements testable
- Branch-per-spec approach (similar to OpenIntegrity work streams)
- AI agents can work from specs directly

## Potential Applications in OpenIntegrity

### 1. Work Stream TDD Tracking

Add TDD phase tracking to WORK_STREAM_TASKS.md:

```markdown
- [ ] **Implement validation function** [feature/example]
  - TDD Phase: RED → GREEN → REFACTOR
  - Red Commit: abc123 (test written)
  - Green Commit: def456 (test passes)
  - Refactor Commits: ghi789, jkl012
```

### 2. Nickel Schema for TDD Phases

```nickel
{
  task = {
    tdd_phase | [| 'red, 'green, 'refactor, 'none |],
    commits = {
      red_commit | String | optional,
      green_commit | String | optional,
      refactor_commits | Array String | default = [],
    },
  },
}
```

### 3. Cryptographic Verification

Verify test-first development:
1. Check red_commit exists before green_commit (chronologically)
2. Verify both commits are signed
3. Prove test file modified before implementation file
4. Track refactor commits maintain green state

### 4. Spec-Driven Work Stream Management

Apply Kiro's three-phase approach:
- **Stage 1: Requirements & Design** = requirements.md + design.md
- **Stage 2-N: Implementation** = tasks.md with TDD tracking
- Each stage tracked in structured format (TOML/JSON/YAML/Nickel)

## Code Examples

### Kiro-Style Task Tracking

```markdown
## Task: Add validation function

**TDD Phase**: GREEN
**Status**: Complete

- [x] RED: Write test for validation (commit: abc123)
- [x] GREEN: Implement validation to pass test (commit: def456)
- [x] REFACTOR: Extract helper functions (commit: ghi789)
```

### Nickel Implementation

```nickel
{
  task = {
    name = "Add validation function",
    tdd_workflow = {
      current_phase = 'green,

      red = {
        commit = "abc123",
        test_file = "tests/test_validation.sh",
        timestamp = "2025-10-21T10:00:00Z",
      },

      green = {
        commit = "def456",
        implementation_file = "src/validation.sh",
        timestamp = "2025-10-21T11:00:00Z",
      },

      refactor = [
        {
          commit = "ghi789",
          description = "Extract helper functions",
          timestamp = "2025-10-21T12:00:00Z",
        },
      ],
    },
  },
}
```

## Related Research

- [spec-kit](../spec-driven-development/spec-kit.md) - GitHub's spec-first approach
- [Tessl Framework](../spec-driven-development/tessl.md) - Specs as primary artifact
- [Nickel Language](../nickel-language/contracts.md) - Runtime validation

## Open Questions

- [ ] How to validate TDD phase progression automatically?
- [ ] Should TDD be mandatory or optional per task?
- [ ] How to handle tasks where TDD doesn't make sense (docs, config)?
- [ ] Can we cryptographically verify RED preceded GREEN using only git history?
- [ ] Integration with existing OpenIntegrity regression tests?

## Implementation Status

✅ **Researched**: Documented Kiro Specs approach
🔄 **Proposed**: Added to work-stream-integrity proposal (PR #4)
⏳ **Pending**: Awaiting community feedback in OpenIntegrityProject

## References

- **Primary**: https://kiro.dev/docs/specs/
- **Concepts**: https://kiro.dev/docs/specs/concepts
- **Best Practices**: https://kiro.dev/docs/specs/best-practices
- **Martin Fowler Analysis**: https://martinfowler.com/articles/exploring-gen-ai/sdd-3-tools.html
- **Hacker News Discussion**: https://news.ycombinator.com/item?id=45610996

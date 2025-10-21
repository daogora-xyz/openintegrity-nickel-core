# Relationship to OpenIntegrityProject

## TL;DR

**openintegrity-nickel-core** is a proof-of-concept research companion to [OpenIntegrityProject/core](https://github.com/OpenIntegrityProject/core), not a fork or competing implementation.

## What This Project IS

✅ **Research Exploration**: Testing Nickel contract validation for work stream management
✅ **Proof of Concept**: Validating ideas before proposing to original project
✅ **Inspiration Source**: Demonstrating what's possible with runtime contracts
✅ **Learning Exercise**: Understanding OpenIntegrity concepts deeply
✅ **Contribution Pathway**: Documenting findings to share with original project

## What This Project IS NOT

❌ **Not a Fork**: Independent codebase, different tech stack
❌ **Not a Replacement**: No intention to compete or supersede original
❌ **Not Seeking Adoption**: Original project has no obligation to adopt these ideas
❌ **Not Better/Worse**: Different approach, different trade-offs
❌ **Not Maintained Long-Term**: This is an experiment, not production software

## Why Separate Repository?

### Rationale

1. **Paradigm Shift**: Nickel contracts vs shell scripts is fundamentally different
2. **Experimental Freedom**: Can try radical ideas without affecting original
3. **Clear Boundaries**: No confusion about intent or ownership
4. **Easy Abandonment**: If ideas don't work, no harm to original
5. **Independent Evolution**: Both projects can evolve without coordination

### Not a Fork Because

- **Different Tech Stack**: Nickel configuration language vs Zsh scripts
- **Different Scope**: Work stream validation vs full inception repository tooling
- **Different Audience**: Nickel/Nix users vs general Git/shell users
- **No Merge Intent**: Not planning PRs to merge code back

## Upstream Relationship

### Tracking Original Project

We maintain awareness of OpenIntegrityProject's evolution via:

```bash
# Fetch latest state using repomix
./scripts/sync-upstream.sh
```

This creates `upstream-snapshot/` with a compressed view of the original project for reference.

### Sync Policy

- **Do NOT** automatically sync code from upstream
- **Do** track conceptual changes and discussions
- **Do** reference original project's documentation
- **Do** acknowledge original project's innovations

### Contribution Policy

We contribute back to OpenIntegrityProject via:

1. **Discussions**: Participate in original repo's issues/discussions
2. **Documentation**: Share learnings about contract validation approaches
3. **Concepts**: Propose ideas validated here as RFCs in original project
4. **NOT Code PRs**: We don't submit code for merging (different paradigms)

## Attribution & Credit

### Original Concepts

All foundational concepts belong to OpenIntegrityProject:

- **Inception Commit**: Cryptographically signed root of trust
- **Progressive Trust Model**: Phased verification approach
- **Work Stream Management**: Branch-tagged task tracking
- **Platform-Agnostic Design**: Git-based, no vendor lock-in

### Our Contribution

We explore **how** to implement these concepts with:

- **Nickel Contracts**: Runtime validation of schemas
- **Type Safety**: Catch errors at "compile time"
- **Living Documentation**: Generate docs from validated source
- **TDD Tracking**: Cryptographic proof of test-first development

## License Compatibility

- **Original**: BSD-2-Clause-Patent
- **This Project**: BSD-2-Clause-Patent (same license)
- **Why**: Ensures compatibility if original adopts any ideas

## Long-Term Vision

### If Successful

If Nickel contract validation proves valuable:

1. **Share Findings**: Document what worked/didn't in `docs/`
2. **Propose to Original**: Open RFC discussion in OpenIntegrityProject
3. **Support Adoption**: Help original project adopt concepts if interested
4. **Archive This Repo**: Mark as "Mission Accomplished" if ideas integrated

### If Unsuccessful

If contracts don't add value:

1. **Document Why**: Write postmortem explaining lessons learned
2. **Archive Repo**: Mark as completed research with no further development
3. **No Harm Done**: Original project unaffected by failed experiment

## Communication Guidelines

### When Referencing This Project

✅ "Inspired by OpenIntegrityProject's vision"
✅ "Exploring Nickel contracts for concepts from OpenIntegrityProject"
✅ "Proof-of-concept companion to OpenIntegrityProject"

❌ "Better implementation of OpenIntegrityProject"
❌ "Fork of OpenIntegrityProject"
❌ "Replacement for OpenIntegrityProject"

### When Discussing in Original Project

- Be respectful and humble
- Frame as "experiments we tried" not "what you should do"
- Acknowledge original project's priorities and roadmap
- Accept if ideas are not adopted

## Acknowledgments

This project exists only because OpenIntegrityProject created compelling concepts worth exploring. We owe a debt of gratitude to the original maintainers for their vision and pioneering work in cryptographically verifiable Git workflows.

## Contact

For questions about this relationship:

- **This Project**: Open an issue in openintegrity-nickel-core
- **Original Project**: Direct questions to OpenIntegrityProject/core
- **Integration**: Discuss in OpenIntegrityProject's issue tracker, not here

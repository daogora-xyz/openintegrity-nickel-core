# OpenIntegrity Nickel Core

A proof-of-concept implementation exploring runtime contract validation for cryptographically verifiable work stream management, inspired by [OpenIntegrityProject](https://github.com/OpenIntegrityProject/core).

## ⚠️ Relationship to OpenIntegrityProject

This is **NOT a fork or replacement**. It's a companion research project that reimagines OpenIntegrity's concepts using Nickel's contract system. See [RELATIONSHIP.md](RELATIONSHIP.md) for details.

## Vision

Explore how [Nickel](https://nickel-lang.org)'s runtime contract validation could enhance OpenIntegrity's core concepts:

- **Cryptographically Verifiable Work Streams**: Enforce workflow policies via contracts
- **TDD Integration**: Track RED-GREEN-REFACTOR cycles with cryptographic proof
- **Platform-Agnostic Configuration**: Git-based, no vendor lock-in
- **Runtime Validation**: Catch errors before execution, not after
- **Living Documentation**: Generate markdown/JSON from validated Nickel source

## Quick Start

```bash
# Sync latest OpenIntegrityProject state for reference
./scripts/sync-upstream.sh

# Install Nickel (via Nix)
nix-shell -p nickel

# Validate example work stream
nickel export <<< 'import "examples/simple-work-stream.ncl"'

# Initialize encrypted session storage (NEW!)
./scripts/encryption/session-encrypt.sh init

# Encrypt agent session data for private storage in public repos
./scripts/encryption/session-encrypt.sh encrypt my-session.txt

# Generate markdown documentation
./generators/generate-markdown.sh
```

## Project Structure

```
openintegrity-nickel-core/
├── nickel/
│   ├── schemas/          # Nickel contract definitions
│   ├── config/           # Project configuration
│   └── validators/       # Validation scripts
├── generators/           # Export to markdown/JSON
├── examples/             # Example Nickel configs
├── docs/
│   ├── research/         # Curated inspiration & research
│   └── COMPARISON.md     # vs original implementation
├── scripts/
│   ├── sync-upstream.sh  # Fetch latest OpenIntegrityProject
│   ├── encryption/       # Session encryption tools
│   └── .git-hooks/       # Git hooks for validation
├── .sessions/            # Encrypted agent sessions
│   ├── encrypted/        # Encrypted files (can be public)
│   └── keys/             # Encryption keys (gitignored)
└── upstream-snapshot/    # Latest OpenIntegrityProject state (repomix)
```

## Key Features

### 1. Encrypted Session Storage ✨ NEW

Store agent conversations and sensitive work stream data securely in public repositories using modern encryption. See [docs/ENCRYPTION.md](docs/ENCRYPTION.md) for details.

```bash
# Initialize encryption
./scripts/encryption/session-encrypt.sh init

# Encrypt a session
./scripts/encryption/session-encrypt.sh encrypt my-conversation.txt

# Commit encrypted version safely to public repo
git add .sessions/encrypted/
git commit -m "Add encrypted agent session"
```

**Features:**
- Private agent conversations in public repositories
- BIP-32 hierarchical key derivation for organized key management
- Nickel contracts for encrypted session metadata
- Session references in work stream tracking

### 2. Work Stream Contracts

```nickel
{
  work_stream = {
    branch | String,
    status | [| 'planning, 'in_progress, 'completed |],

    stages | Array {
      name | String,
      tasks | Array {
        content | String,
        tdd_phase | [| 'red, 'green, 'refactor, 'none |],
      },
    },
  },
}
```

### 3. Cryptographic Verification

```nickel
{
  pr_policy = {
    status_before_code | Boolean = true,
    verify_signatures | Boolean = true,

    dependency_chain | Array {
      pr_id | String,
      depends_on | String,  # commit hash
      verified_at | String,  # timestamp
    },
  },
}
```

### 4. TDD Workflow Tracking

```nickel
{
  test_spec = {
    red_commit | String,    # Test written
    green_commit | String,  # Test passes
    refactor_commits | Array String,

    cryptographic_proof = {
      red_preceded_green | Boolean,
      all_signed | Boolean,
    },
  },
}
```

## Research & Inspiration

See [docs/research/](docs/research/) for curated content that inspires features:

- Kiro Specs (TDD tracking)
- spec-kit (spec-first development)
- Nickel language capabilities
- Architecture Decision Records (ADRs)
- Living Documentation patterns

## Syncing with Upstream

```bash
# Fetch latest OpenIntegrityProject state via repomix
./scripts/sync-upstream.sh

# View changes since last sync
git diff upstream-snapshot/
```

## Goals

1. **Validate Ideas**: Test contract-based work stream management in practice
2. **Document Learnings**: What works, what doesn't, why
3. **Inspire Original**: Contribute concepts back to OpenIntegrityProject
4. **No Competition**: This is research, not a replacement

## Acknowledgments

Built with deep respect for OpenIntegrityProject's vision of cryptographically verifiable trust chains and inception commits. All credit for foundational concepts goes to the original project maintainers.

This project exists to explore "what if?" questions and hopefully contribute insights back to the community.

## License

BSD-2-Clause-Patent (same as OpenIntegrityProject for compatibility)

See [LICENSE](LICENSE) for full text.

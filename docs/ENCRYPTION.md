# Encrypted Session Storage

**NEW FEATURE**: Store sensitive agent conversations and work stream data securely in public repositories.

## Overview

OpenIntegrity Nickel Core supports encrypted storage of agent sessions, allowing you to:

- **Keep conversations private** while storing them in public repositories
- **Resume agent sessions** across different machines securely
- **Track work streams** with full context without exposing sensitive details
- **Use hierarchical key derivation** for organized, recoverable encryption keys

This feature extends the original OpenIntegrityProject concept by adding privacy-preserving session management.

## Quick Start

### 1. Install Dependencies

```bash
# macOS
brew install age

# Ubuntu/Debian
apt install age

# Arch Linux
pacman -S age

# From source
# https://github.com/FiloSottile/age
```

### 2. Initialize Encryption

```bash
# Generate encryption key
./scripts/encryption/session-encrypt.sh init

# Verify setup
./scripts/encryption/session-encrypt.sh verify
```

### 3. Encrypt a Session

```bash
# Encrypt your session file
./scripts/encryption/session-encrypt.sh encrypt my-conversation.txt

# List encrypted sessions
./scripts/encryption/session-encrypt.sh list
```

### 4. Decrypt When Needed

```bash
# Decrypt a specific session
./scripts/encryption/session-encrypt.sh decrypt .sessions/encrypted/20250121-120000-a1b2c3d4.age

# Output: 20250121-120000-a1b2c3d4.decrypted
```

## Architecture

### Directory Structure

```
.sessions/
├── encrypted/              # Encrypted session files (CAN be committed)
│   ├── 20250121-session.age
│   ├── 20250121-session.metadata.ncl
│   └── ...
├── keys/                   # Encryption keys (NEVER committed - in .gitignore)
│   ├── session.key         # Default age key
│   └── master.seed         # BIP32 master seed (optional)
└── session-index.ncl       # Public index of all sessions
```

### What Gets Committed

✅ **Safe to commit:**
- `.sessions/encrypted/*.age` - Encrypted session files
- `.sessions/encrypted/*.metadata.ncl` - Session metadata
- `.sessions/session-index.ncl` - Session index

❌ **NEVER commit:**
- `.sessions/keys/*` - Encryption keys (automatically gitignored)
- `*.decrypted` - Decrypted session files (automatically gitignored)

## Usage Patterns

### Basic Workflow

```bash
# 1. Initialize (once per repository)
./scripts/encryption/session-encrypt.sh init

# 2. Work on your project with agent sessions
# ... save your conversation to a file ...

# 3. Encrypt the session before committing
./scripts/encryption/session-encrypt.sh encrypt agent-session-001.txt

# 4. Commit the encrypted version (safe for public repos)
git add .sessions/encrypted/
git commit -m "Add encrypted agent session"

# 5. On another machine, decrypt when needed
git clone <your-repo>
# ... copy your .sessions/keys/session.key from secure backup ...
./scripts/encryption/session-encrypt.sh decrypt .sessions/encrypted/20250121-*.age
```

### Advanced: BIP32 Hierarchical Keys

For multiple session types with deterministic key derivation:

```bash
# 1. Generate master seed (backup this securely!)
./scripts/encryption/bip32-keygen.sh init

# 2. Derive keys for different session types
./scripts/encryption/bip32-keygen.sh derive planning 0
./scripts/encryption/bip32-keygen.sh derive dev 0
./scripts/encryption/bip32-keygen.sh derive review 0

# 3. Use derived keys with age encryption
age -e -r <pubkey-from-derived-key> -o session.age session.txt

# 4. Backup master seed
./scripts/encryption/bip32-keygen.sh backup
```

**BIP32 Derivation Paths:**
```
m / purpose / repository / session_type / session_index

Examples:
  m/session/0/planning/0    - First planning session
  m/session/0/dev/5         - Sixth development session
  m/session/0/review/2      - Third code review session
```

**Benefits:**
- Single master seed backup recovers all session keys
- Semantic organization by session type
- Deterministic key recovery across machines

## Nickel Schema Integration

### Define Encrypted Sessions

```nickel
let schema = import "../nickel/schemas/encrypted-session.ncl" in

{
  metadata = {
    session_id = "my-session-001",
    created_at = "2025-01-21T10:00:00Z",
    updated_at = "2025-01-21T12:00:00Z",
    tags = ["planning", "architecture"],
    description = "Architecture design session",

    encryption = {
      algorithm = 'age,
      encrypted_file = ".sessions/encrypted/my-session-001.age",
      checksum = "abc123...",
    },
  },
} | schema.EncryptedSession
```

### Work Stream Integration

See `examples/encrypted-work-stream.ncl` for a complete example of:
- Public work stream tracking
- Private encrypted session references
- Cryptographic verification metadata

```nickel
{
  work_stream = {
    # Public metadata
    branch = "feature/new-feature",
    status = 'in_progress,

    stages = [{
      name = "Implementation",
      tasks = [{
        content = "Implement core feature",
        status = 'in_progress,

        # Reference to encrypted session (public reference, encrypted content)
        encrypted_session = "20250121-dev-session",
      }],
    }],
  },

  # Session encryption policy
  encryption_policy = {
    auto_encrypt = true,
    require_encryption = true,
    # ... see schema for full options ...
  } | schema.EncryptionPolicy,
}
```

## Security Considerations

### Key Management

1. **Never commit encryption keys**
   - Keys are in `.gitignore`
   - Use environment variables or secret managers for CI/CD
   - Backup keys securely (password manager, encrypted drive)

2. **Key backup strategies:**
   - **Simple**: Back up `.sessions/keys/session.key` to secure location
   - **Advanced**: Use BIP32 master seed for hierarchical key recovery

3. **Key rotation:**
   - Generate new keys periodically (90 days recommended)
   - Re-encrypt old sessions with new keys if needed
   - Track rotation in `session-index.ncl`

### What to Encrypt

Encrypt content containing:
- **Agent conversations** with implementation details
- **API keys, tokens, credentials** (though these should ideally be elsewhere)
- **Internal design discussions** with proprietary information
- **Customer data** or sensitive project information

Don't encrypt:
- **Public work stream metadata** (branch, status, task descriptions)
- **Commit messages** (already in git history)
- **Test results** (unless they expose vulnerabilities)

### Encryption Algorithms

**Default: age**
- Modern, simple, secure
- Public key encryption
- Recommended for most use cases

**Advanced: age + BIP32**
- Hierarchical deterministic key derivation
- Single master seed for all sessions
- Better organization and recovery

**Alternative: GPG**
- Compatible with existing GPG keys
- Wider tool support
- More complex setup

## Troubleshooting

### "Encryption key not found"

```bash
# Verify key exists
ls -la .sessions/keys/session.key

# If missing, initialize or restore from backup
./scripts/encryption/session-encrypt.sh init
# OR
cp /path/to/backup/session.key .sessions/keys/
```

### "Keys directory not gitignored"

```bash
# Verify .gitignore
grep "sessions/keys" .gitignore

# Should show:
# .sessions/keys/

# If missing, the init script will warn you
./scripts/encryption/session-encrypt.sh verify
```

### Decrypt fails with "bad secret key"

- Wrong key being used
- Encrypted with different key than you're using to decrypt
- If using BIP32, verify derivation path matches

```bash
# Check which public key was used (from metadata)
cat .sessions/encrypted/session-id.metadata.ncl

# Compare with your key
grep "public key" .sessions/keys/session.key
```

### Lost encryption key

If using BIP32:
```bash
# Restore from master seed backup
cp /secure/backup/master.seed .sessions/keys/
./scripts/encryption/bip32-keygen.sh derive <session-type> <index>
```

If using simple age keys:
- **Restore from backup** (password manager, encrypted drive)
- If no backup exists: **encrypted data is unrecoverable**

This is why key backup is critical!

## Examples

### Example 1: Encrypt Agent Conversation

```bash
# Save your Claude Code session
cat > my-planning-session.txt << 'EOF'
Session: Planning new encryption feature
Date: 2025-01-21

[Agent conversation details...]
EOF

# Encrypt it
./scripts/encryption/session-encrypt.sh encrypt my-planning-session.txt

# Output:
# Session ID:      20250121-120000-a1b2c3d4
# Encrypted file:  .sessions/encrypted/20250121-120000-a1b2c3d4.age
# Metadata:        .sessions/encrypted/20250121-120000-a1b2c3d4.metadata.ncl

# Commit encrypted version (safe!)
git add .sessions/encrypted/20250121-120000-a1b2c3d4.*
git commit -m "Add encrypted planning session"

# Original plaintext can be deleted
rm my-planning-session.txt
```

### Example 2: Reference in Work Stream

```nickel
# In your work stream config
{
  stages = [{
    name = "Planning",
    tasks = [{
      content = "Design encryption architecture",
      status = 'completed,
      encrypted_session = "20250121-120000-a1b2c3d4",  # Reference encrypted session
    }],
  }],
}
```

### Example 3: Decrypt for Review

```bash
# Later, when you need to review the session
./scripts/encryption/session-encrypt.sh decrypt \
  .sessions/encrypted/20250121-120000-a1b2c3d4.age

# Read the decrypted content
cat 20250121-120000-a1b2c3d4.decrypted

# Delete decrypted version when done (not gitignored but should not be committed)
rm 20250121-120000-a1b2c3d4.decrypted
```

## Integration with OpenIntegrity

This feature **extends** OpenIntegrity concepts:

### Original OpenIntegrity
- Cryptographically verified work streams
- TDD cycle tracking with git commits
- Public trust chain through inception commits

### New Addition: Encrypted Sessions
- **Private context** alongside public work streams
- **Resume agent sessions** without exposing sensitive details
- **Hierarchical key management** using BIP-32 concepts
- **Living documentation** with encrypted session references

### Relationship to Upstream

This is a **research feature** exploring:
> "What if work streams could reference private encrypted context while maintaining public verifiability?"

Learnings may inform future OpenIntegrityProject discussions.

## Best Practices

1. **Always backup encryption keys**
   - Use password manager or encrypted drive
   - Test backup restoration regularly
   - Consider BIP32 master seed for single backup

2. **Encrypt before committing**
   - Never commit plaintext sensitive data
   - Use pre-commit hooks (planned feature)
   - Review with `./scripts/encryption/session-encrypt.sh verify`

3. **Organize sessions semantically**
   - Use BIP32 derivation paths by type
   - Tag sessions with meaningful metadata
   - Reference sessions in work stream tasks

4. **Rotate keys periodically**
   - Generate new keys every 90 days (recommended)
   - Re-encrypt critical sessions
   - Update session index

5. **Audit regularly**
   - List all encrypted sessions: `./scripts/encryption/session-encrypt.sh list`
   - Verify checksums match
   - Ensure keys are properly gitignored

## Future Enhancements

Planned features:

- [ ] Git hooks for automatic encryption detection
- [ ] Pre-commit hook to prevent unencrypted sensitive data
- [ ] Post-checkout hook for optional auto-decrypt
- [ ] Integration with Git LFS for large encrypted sessions
- [ ] Web UI for browsing encrypted session metadata
- [ ] Full BIP32 implementation (currently simplified)
- [ ] Session compression before encryption
- [ ] Multi-recipient encryption (team collaboration)

## References

- [age encryption](https://github.com/FiloSottile/age) - Modern encryption tool
- [BIP-32](https://github.com/bitcoin/bips/blob/master/bip-0032.mediawiki) - Hierarchical Deterministic Wallets
- [BIP-keychain research](docs/research/bip-keychain/overview.md) - Local research notes
- [OpenIntegrityProject](https://github.com/OpenIntegrityProject/core) - Upstream project

## License

BSD-2-Clause-Patent (same as OpenIntegrityProject for compatibility)

# BIP-Keychain

**Source**: https://github.com/akarve/bip-keychain
**Date Discovered**: 2025-10-21
**Relevance**: Semantic key derivation for cryptographic secrets - potentially applicable to hierarchical trust and key management in OpenIntegrity work streams

## Summary

BIP-Keychain is a draft Bitcoin Improvement Proposal that extends BIP-85 (Deterministic Entropy From BIP32 Keychains) with semantic derivation paths. It creates a hierarchical key-value store where keys are meaningful semantic paths derived from JSON-LD schema.org entities, and values are cryptographic secrets.

The key innovation: **separating "derivation path keys" from "derivation path values"** to prevent cascading compromise - if the hot master is compromised, only the paths (not the actual secrets) are exposed.

## Key Features

### 1. Semantic Path Derivation

Uses JSON-LD formatted schema.org entities as derivation path segments:

```
m/83696968'/67797668'/{SEMANTIC_PATH_IMAGE}
```

- `83696968'` = BIP-85 prefix
- `67797668'` = BIP-Keychain application code
- `{SEMANTIC_PATH_IMAGE}` = Semantic path converted to numeric indices via HMAC-SHA-512

### 2. Separation of Keys and Values

**Traditional approach** (single master key):
```
Master Seed → All Secrets
    ↓ (if compromised)
Everything lost
```

**BIP-Keychain approach**:
```
Master Seed → Derivation Paths (metadata)
Cold Storage Key → Actual Secrets
    ↓ (if hot master compromised)
Only paths exposed, secrets remain safe
```

### 3. Long Path Support

Handles derivation paths with potentially **thousands of segments**, enabling fine-grained hierarchical organization.

### 4. Flexible Hardening

Relaxes BIP-85's requirement for fully hardened derivation to enable **PKI use cases** (public key infrastructure).

### 5. Just-in-Time Secret Delivery

Secrets can be provided by a server-side key derivation service without storing the master key online.

## Technical Architecture

### Path Derivation Algorithm

1. **Input**: JSON-LD entity (e.g., website, location, organization)
2. **HMAC-SHA-512**: Hash entity with parent entropy as key
3. **Convert to index**: First 4 bytes → uint32 child index
4. **BIP-32 derivation**: Derive child key at that index
5. **Repeat**: For each segment in semantic path

### Example: Web Password Derivation

```json
{
  "@context": "https://schema.org",
  "@type": "WebSite",
  "url": "https://example.com"
}
```

Becomes derivation path:
```
m/83696968'/67797668'/2891336107'/...
```

The final secret is deterministically derived but path has semantic meaning.

## Insights for OpenIntegrity

### What We Learned

1. **Hierarchical secrets management**: BIP-32 can organize more than just Bitcoin keys
2. **Semantic paths**: Human-readable structure maps to cryptographic derivation
3. **Progressive disclosure**: Can reveal path structure without revealing secrets
4. **Schema.org integration**: Standardized entities enable interoperability

### What Surprised Us

- Separation of path keys vs. value keys (security property)
- Long path support (thousands of segments)
- JSON-LD as derivation input (semantic web meets crypto)
- PKI compatibility (non-hardened derivation)

## Potential Applications in OpenIntegrity

### 1. Hierarchical Repository Trust

```
m/83696968'/67797668'/
  ├─ {github.com}/{org}/{repo}/ → Repository identity key
  ├─ {github.com}/{org}/{repo}/inception → Inception commit signing key
  ├─ {github.com}/{org}/{repo}/maintainers/{alice} → Delegated authority key
  └─ {github.com}/{org}/{repo}/maintainers/{bob} → Delegated authority key
```

### 2. Work Stream Key Derivation

```nickel
{
  key_derivation = {
    method = 'bip_keychain,

    base_path = "m/83696968'/67797668'",

    # Semantic path structure
    semantic_path = {
      platform = "github.com",
      organization = "OpenIntegrityProject",
      repository = "core",
      work_stream = "feature/hardware-signing",
    },

    # Derived keys
    signing_key | String,  # For commits
    verification_key | String,  # Public key
  },
}
```

### 3. Progressive Trust with Semantic Paths

Map OpenIntegrity trust phases to derivation paths:

```
m/.../repo/inception_authority → Initial trust anchor
m/.../repo/delegated_authority/{maintainer} → Delegated keys
m/.../repo/distributed_authority/{contributor} → Contributor keys
m/.../repo/autonomous_authority/{bot} → Automated signing
```

### 4. Cryptographic Proof of Path

Since paths are deterministically derived from semantic entities:
- Can prove a key belongs to a specific repository/work stream
- Can verify hierarchical relationships
- Can audit key structure without exposing secrets

## Code Examples

### Semantic Path to BIP-32 Derivation

```python
import hmac
import hashlib
import json

def semantic_path_to_index(json_ld_entity, parent_entropy):
    """Convert JSON-LD entity to BIP-32 child index."""
    # Serialize entity
    entity_bytes = json.dumps(json_ld_entity, sort_keys=True).encode()

    # HMAC with parent entropy
    h = hmac.new(parent_entropy, entity_bytes, hashlib.sha512)

    # First 4 bytes as uint32
    index = int.from_bytes(h.digest()[:4], 'big')

    return index

# Example: Repository identity
repo_entity = {
    "@context": "https://schema.org",
    "@type": "SoftwareSourceCode",
    "codeRepository": "https://github.com/OpenIntegrityProject/core"
}

index = semantic_path_to_index(repo_entity, parent_entropy)
# Derive child at m/83696968'/67797668'/{index}'
```

### Nickel Schema for BIP-Keychain Paths

```nickel
{
  bip_keychain_config = {
    base_path = "m/83696968'/67797668'",

    # Repository identity
    repository = {
      "@context" = "https://schema.org",
      "@type" = "SoftwareSourceCode",
      codeRepository | String,
    },

    # Derived keys
    keys = {
      inception_key = {
        path_suffix = "/inception",
        purpose = "Sign inception commit",
        hardened = true,
      },

      work_stream_key = {
        path_suffix = "/work-streams/{name}",
        purpose = "Sign work stream commits",
        hardened = true,
      },
    },
  },
}
```

## Comparison to Other Approaches

### vs. BIP-85 (Standard)

| Feature | BIP-85 | BIP-Keychain |
|---------|--------|--------------|
| Derivation | Numeric indices | Semantic paths |
| Path length | Short (3-4 levels) | Long (thousands) |
| Hardening | Fully hardened | Flexible |
| Use case | Bitcoin wallets | General secrets |

### vs. Traditional Key Management

| Feature | Traditional | BIP-Keychain |
|---------|-------------|--------------|
| Storage | Key files | Seed phrase |
| Hierarchy | File system | Cryptographic |
| Backup | Multiple files | Single seed |
| Semantics | Filenames | JSON-LD |

## Related Research

- [BIP-85 (Deterministic Entropy)](https://bips.dev/85/) - Parent standard
- [BIP-32 (HD Wallets)](https://github.com/bitcoin/bips/blob/master/bip-0032.mediawiki) - Underlying tech
- [SeedPass](../bip-85/seedpass.md) - Password derivation using BIP-85
- [Kiro Specs](../kiro-specs/overview.md) - Spec-driven development with TDD

## Open Questions

- [ ] How to integrate with Git's existing SSH/GPG signing?
- [ ] Should semantic paths be stored in repository metadata?
- [ ] Can BIP-Keychain paths be validated by Nickel contracts?
- [ ] How to handle key rotation with deterministic derivation?
- [ ] What's the performance impact of long derivation paths?
- [ ] Should inception commits include the derivation path?

## Implementation Status

✅ **Researched**: Documented BIP-Keychain approach
⏳ **Draft**: BIP remains in draft status (no reference implementation yet)
🔄 **Proposed**: Could add to work-stream-integrity research
⏳ **Pending**: Needs evaluation by OpenIntegrityProject community

## Security Considerations

### Advantages

1. **Single backup**: One seed phrase protects all keys
2. **Hierarchical organization**: Clear key relationships
3. **Deterministic**: Keys can be regenerated from seed
4. **Separation of concerns**: Path metadata ≠ secrets

### Risks

1. **Seed compromise**: If seed is lost, all keys are compromised
2. **Derivation complexity**: Long paths increase computation
3. **Path disclosure**: Semantic paths might leak metadata
4. **Non-standard**: Limited tooling/ecosystem support

## References

- **GitHub**: https://github.com/akarve/bip-keychain
- **BIP-85**: https://bips.dev/85/
- **BIP-32**: https://github.com/bitcoin/bips/blob/master/bip-0032.mediawiki
- **JSON-LD**: https://json-ld.org/
- **Schema.org**: https://schema.org/

## License

BIP-Keychain is licensed under BSD-2-Clause (compatible with OpenIntegrityProject).

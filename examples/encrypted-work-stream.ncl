# Encrypted Work Stream Example
#
# Demonstrates integration of work stream tracking with encrypted session storage.
# This allows public repositories to track project progress while keeping
# sensitive agent conversations and implementation details private.

let session_schema = import "../nickel/schemas/encrypted-session.ncl" in

{
  # Work stream metadata (public)
  work_stream = {
    branch
      | doc "Git branch for this work stream"
      | String
      = "feature/encrypted-sessions",

    status
      | doc "Current work stream status"
      | [| 'planning, 'in_progress, 'completed |]
      = 'in_progress,

    public_description
      | doc "Public description of work being done"
      | String
      = "Add encrypted session storage feature for private agent conversations in public repos",

    stages
      | doc "Development stages"
      | Array {
          name | String,
          status | [| 'pending, 'in_progress, 'completed |],

          tasks | Array {
            content | String,
            status | [| 'pending, 'in_progress, 'completed |],
            tdd_phase | [| 'red, 'green, 'refactor, 'none |] | optional,

            # Reference to encrypted session data
            encrypted_session | String | optional,
          },
        }
      = [
        {
          name = "Planning & Design",
          status = 'completed,
          tasks = [
            {
              content = "Design encryption system architecture",
              status = 'completed,
              encrypted_session = "20250121-planning-architecture",
            },
            {
              content = "Research BIP-32 key derivation integration",
              status = 'completed,
              encrypted_session = "20250121-research-bip32",
            },
          ],
        },
        {
          name = "Implementation",
          status = 'in_progress,
          tasks = [
            {
              content = "Create Nickel schemas for encrypted sessions",
              status = 'completed,
              tdd_phase = 'green,
            },
            {
              content = "Implement encryption/decryption scripts",
              status = 'completed,
              tdd_phase = 'green,
            },
            {
              content = "Add example configurations and documentation",
              status = 'in_progress,
              encrypted_session = "20250121-dev-examples",
            },
          ],
        },
      ],
  },

  # Encryption policy (public configuration)
  encryption_policy = {
    policy_name = "work-stream-sessions",
    auto_encrypt = true,
    require_encryption = true,

    key_management = {
      storage_location = 'git_ignored_file,
      key_rotation_days = 90,
      bip32_enabled = true,  # Use hierarchical key derivation
      master_key_backup = true,
    },

    content_filters = {
      patterns = [
        "API[_-]?KEY",
        "SECRET",
        "PASSWORD",
        "PRIVATE[_-]?KEY",
        "SESSION[_-]?TOKEN",
      ],
      file_types = [
        ".session",
        ".conversation",
        ".agent",
        ".claude",
      ],
    },

    git_integration = {
      pre_commit_check = true,
      auto_decrypt_on_checkout = false,
    },
  } | session_schema.EncryptionPolicy,

  # Session index (references to encrypted content)
  sessions = [
    {
      metadata = {
        session_id = "20250121-planning-architecture",
        created_at = "2025-01-21T10:00:00Z",
        updated_at = "2025-01-21T12:00:00Z",
        tags = ["planning", "architecture", "encryption"],
        description = "Initial architecture design session for encryption feature",

        encryption = {
          algorithm = 'age_bip32,
          key_derivation = {
            method = 'bip32,
            path = "m/session/0/planning/0",
          },
          encrypted_file = ".sessions/encrypted/20250121-planning-architecture.age",
          checksum = "abcd1234...",  # SHA256 of encrypted file
        },
      },
    },
    {
      metadata = {
        session_id = "20250121-dev-examples",
        created_at = "2025-01-21T14:00:00Z",
        updated_at = "2025-01-21T15:30:00Z",
        tags = ["development", "examples", "documentation"],
        description = "Development session creating examples and documentation",

        encryption = {
          algorithm = 'age_bip32,
          key_derivation = {
            method = 'bip32,
            path = "m/session/0/dev/0",
          },
          encrypted_file = ".sessions/encrypted/20250121-dev-examples.age",
          checksum = "efgh5678...",
        },
      },
    },
  ] | Array session_schema.EncryptedSession,

  # Verification metadata (cryptographic proof)
  verification = {
    inception_commit
      | doc "Initial commit establishing work stream"
      | String
      | optional
      = "feabf5a",

    signed_commits
      | doc "List of cryptographically signed commits"
      | Array String
      | optional
      = [],

    encrypted_sessions_count
      | doc "Number of encrypted sessions referenced"
      | Number
      = 2,

    last_verified
      | doc "Timestamp of last verification"
      | String
      = "2025-01-21T15:30:00Z",
  },
}

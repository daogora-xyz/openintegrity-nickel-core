# Encrypted Session Schema
#
# Defines contracts for encrypted agent session data storage,
# enabling private conversations in public repositories.

{
  EncryptedSession = {
    metadata
      | doc "Session metadata (stored in plaintext)"
      | {
          session_id
            | doc "Unique identifier for this session"
            | String,

          created_at
            | doc "ISO 8601 timestamp of session creation"
            | String,

          updated_at
            | doc "ISO 8601 timestamp of last update"
            | String,

          tags
            | doc "Searchable tags for session categorization"
            | Array String
            | optional,

          description
            | doc "Brief description of session purpose"
            | String
            | optional,

          encryption
            | doc "Encryption metadata"
            | {
                algorithm
                  | doc "Encryption algorithm used"
                  | [| 'age, 'gpg, 'age_bip32 |]
                  | default = 'age,

                key_derivation
                  | doc "Key derivation method (if applicable)"
                  | {
                      method
                        | doc "Derivation method"
                        | [| 'none, 'bip32, 'pbkdf2 |]
                        | default = 'none,

                      path
                        | doc "Derivation path (BIP32 format: m/purpose'/coin'/...)"
                        | String
                        | optional,
                    }
                  | optional,

                encrypted_file
                  | doc "Path to encrypted content file (relative to repo root)"
                  | String,

                checksum
                  | doc "SHA256 checksum of encrypted file for integrity verification"
                  | String
                  | optional,
              },
        },

    # Note: Actual encrypted content stored separately in .sessions/encrypted/
    # This schema only tracks metadata and references
  },

  EncryptionPolicy = {
    policy_name
      | doc "Name of this encryption policy"
      | String,

    auto_encrypt
      | doc "Automatically encrypt sessions matching criteria"
      | Boolean
      | default = false,

    require_encryption
      | doc "Require encryption for sessions matching criteria"
      | Boolean
      | default = false,

    key_management
      | doc "Key management configuration"
      | {
          storage_location
            | doc "Where encryption keys are stored"
            | [| 'local_keyring, 'git_ignored_file, 'env_var, 'external_kms |]
            | default = 'git_ignored_file,

          key_rotation_days
            | doc "Days before suggesting key rotation (0 = no rotation)"
            | Number
            | default = 0,

          bip32_enabled
            | doc "Enable BIP32 hierarchical deterministic key derivation"
            | Boolean
            | default = false,

          master_key_backup
            | doc "Require master key backup before use"
            | Boolean
            | default = true,
        },

    content_filters
      | doc "What content should trigger encryption"
      | {
          patterns
            | doc "Regex patterns to detect sensitive content"
            | Array String
            | default = [],

          file_types
            | doc "File extensions to always encrypt"
            | Array String
            | default = [".session", ".conversation", ".agent"],
        },

    git_integration
      | doc "Git hooks and automation"
      | {
          pre_commit_check
            | doc "Check for unencrypted sensitive data before commit"
            | Boolean
            | default = true,

          auto_decrypt_on_checkout
            | doc "Automatically decrypt sessions on branch checkout"
            | Boolean
            | default = false,
        },
  },

  SessionIndex = {
    index_version
      | doc "Schema version of this index"
      | String
      | default = "1.0.0",

    sessions
      | doc "Array of all encrypted sessions"
      | Array EncryptedSession,

    policy
      | doc "Encryption policy for this repository"
      | EncryptionPolicy
      | optional,

    statistics
      | doc "Usage statistics"
      | {
          total_sessions | Number,
          encrypted_sessions | Number,
          total_size_bytes | Number | optional,
          last_updated | String,
        }
      | optional,
  },
}

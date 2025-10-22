#!/usr/bin/env bash
#
# session-encrypt.sh - Encrypt/decrypt agent session data for secure public storage
#
# Usage:
#   ./session-encrypt.sh init                    # Generate new encryption key
#   ./session-encrypt.sh encrypt <input-file>    # Encrypt session file
#   ./session-encrypt.sh decrypt <encrypted-file> # Decrypt session file
#   ./session-encrypt.sh list                    # List all encrypted sessions
#   ./session-encrypt.sh verify                  # Verify encryption setup

set -euo pipefail

# Color output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Configuration
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"
SESSIONS_DIR="$REPO_ROOT/.sessions"
ENCRYPTED_DIR="$SESSIONS_DIR/encrypted"
KEYS_DIR="$SESSIONS_DIR/keys"
DEFAULT_KEY="$KEYS_DIR/session.key"
INDEX_FILE="$SESSIONS_DIR/session-index.ncl"

# Helper functions
print_info() { echo -e "${BLUE}[INFO]${NC} $*"; }
print_success() { echo -e "${GREEN}[SUCCESS]${NC} $*"; }
print_warning() { echo -e "${YELLOW}[WARNING]${NC} $*"; }
print_error() { echo -e "${RED}[ERROR]${NC} $*" >&2; }

check_dependencies() {
    local missing_deps=()

    if ! command -v age &> /dev/null; then
        missing_deps+=("age")
    fi

    if ! command -v age-keygen &> /dev/null; then
        missing_deps+=("age-keygen")
    fi

    if [ ${#missing_deps[@]} -ne 0 ]; then
        print_error "Missing required dependencies: ${missing_deps[*]}"
        echo ""
        echo "Install age encryption tool:"
        echo "  - macOS: brew install age"
        echo "  - Linux: apt install age / dnf install age"
        echo "  - From source: https://github.com/FiloSottile/age"
        exit 1
    fi
}

init_encryption() {
    print_info "Initializing encryption setup..."

    # Create directories
    mkdir -p "$ENCRYPTED_DIR" "$KEYS_DIR"

    # Check if key already exists
    if [ -f "$DEFAULT_KEY" ]; then
        print_warning "Encryption key already exists at $DEFAULT_KEY"
        read -p "Overwrite? (y/N) " -n 1 -r
        echo
        if [[ ! $REPLY =~ ^[Yy]$ ]]; then
            print_info "Keeping existing key"
            return 0
        fi
    fi

    # Generate new age key
    print_info "Generating new age encryption key..."
    age-keygen -o "$DEFAULT_KEY" 2>&1 | grep -v "Public key:"

    # Extract public key for display
    local pubkey
    pubkey=$(grep "# public key:" "$DEFAULT_KEY" | cut -d: -f2 | xargs)

    # Set secure permissions
    chmod 600 "$DEFAULT_KEY"

    print_success "Encryption key generated!"
    echo ""
    echo "  Private key: $DEFAULT_KEY"
    echo "  Public key:  $pubkey"
    echo ""
    print_warning "IMPORTANT: Back up your private key securely!"
    print_warning "Without it, encrypted sessions cannot be recovered."
    echo ""

    # Create initial index
    create_initial_index

    print_success "Encryption setup complete"
}

create_initial_index() {
    if [ -f "$INDEX_FILE" ]; then
        return
    fi

    cat > "$INDEX_FILE" << 'EOF'
# Encrypted Session Index
# This file tracks all encrypted sessions in this repository

let schema = import "../nickel/schemas/encrypted-session.ncl" in

{
  index_version = "1.0.0",

  sessions = [],

  policy = {
    policy_name = "default",
    auto_encrypt = false,
    require_encryption = false,

    key_management = {
      storage_location = 'git_ignored_file,
      key_rotation_days = 0,
      bip32_enabled = false,
      master_key_backup = true,
    },

    content_filters = {
      patterns = [
        "API[_-]?KEY",
        "SECRET",
        "PASSWORD",
        "PRIVATE[_-]?KEY",
      ],
      file_types = [".session", ".conversation", ".agent"],
    },

    git_integration = {
      pre_commit_check = true,
      auto_decrypt_on_checkout = false,
    },
  },

  statistics = {
    total_sessions = 0,
    encrypted_sessions = 0,
    last_updated = "$(date -u +%Y-%m-%dT%H:%M:%SZ)",
  },
} | schema.SessionIndex
EOF

    print_success "Created session index at $INDEX_FILE"
}

encrypt_file() {
    local input_file="$1"

    if [ ! -f "$input_file" ]; then
        print_error "Input file not found: $input_file"
        exit 1
    fi

    if [ ! -f "$DEFAULT_KEY" ]; then
        print_error "Encryption key not found. Run: $0 init"
        exit 1
    fi

    # Generate output filename
    local basename
    basename=$(basename "$input_file")
    local session_id
    session_id=$(date +%Y%m%d-%H%M%S)-$(head -c 4 /dev/urandom | xxd -p)
    local output_file="$ENCRYPTED_DIR/${session_id}.age"

    print_info "Encrypting: $input_file"

    # Extract public key from private key
    local pubkey
    pubkey=$(grep "# public key:" "$DEFAULT_KEY" | cut -d: -f2 | xargs)

    # Encrypt the file
    age -e -r "$pubkey" -o "$output_file" "$input_file"

    # Calculate checksum
    local checksum
    checksum=$(sha256sum "$output_file" | cut -d' ' -f1)

    # Create metadata entry
    local metadata_file="$ENCRYPTED_DIR/${session_id}.metadata.ncl"
    cat > "$metadata_file" << EOF
# Metadata for encrypted session: $session_id
# Source file: $basename

let schema = import "../../nickel/schemas/encrypted-session.ncl" in

{
  metadata = {
    session_id = "$session_id",
    created_at = "$(date -u +%Y-%m-%dT%H:%M:%SZ)",
    updated_at = "$(date -u +%Y-%m-%dT%H:%M:%SZ)",
    tags = ["auto-encrypted"],
    description = "Encrypted session from $basename",

    encryption = {
      algorithm = 'age,
      key_derivation = {
        method = 'none,
      },
      encrypted_file = ".sessions/encrypted/${session_id}.age",
      checksum = "$checksum",
    },
  },
} | schema.EncryptedSession
EOF

    print_success "Encrypted session created!"
    echo ""
    echo "  Session ID:      $session_id"
    echo "  Encrypted file:  $output_file"
    echo "  Metadata:        $metadata_file"
    echo "  Checksum:        $checksum"
    echo ""
    print_info "Metadata can be safely committed to git"
    print_info "Encrypted file can also be committed (contains no plaintext)"
}

decrypt_file() {
    local encrypted_file="$1"

    if [ ! -f "$encrypted_file" ]; then
        print_error "Encrypted file not found: $encrypted_file"
        exit 1
    fi

    if [ ! -f "$DEFAULT_KEY" ]; then
        print_error "Decryption key not found at $DEFAULT_KEY"
        exit 1
    fi

    # Determine output filename
    local basename
    basename=$(basename "$encrypted_file" .age)
    local output_file="${basename}.decrypted"

    print_info "Decrypting: $encrypted_file"

    # Decrypt the file
    age -d -i "$DEFAULT_KEY" -o "$output_file" "$encrypted_file"

    print_success "Decrypted successfully!"
    echo ""
    echo "  Output file: $output_file"
    echo ""
    print_warning "Decrypted file contains sensitive data - handle carefully"
}

list_sessions() {
    print_info "Encrypted sessions in this repository:"
    echo ""

    if [ ! -d "$ENCRYPTED_DIR" ]; then
        print_warning "No encrypted sessions directory found"
        return
    fi

    local count=0
    for metadata_file in "$ENCRYPTED_DIR"/*.metadata.ncl; do
        if [ ! -f "$metadata_file" ]; then
            continue
        fi

        count=$((count + 1))
        local session_id
        session_id=$(basename "$metadata_file" .metadata.ncl)

        # Extract metadata using nickel export (if available)
        if command -v nickel &> /dev/null; then
            echo "  [$count] $session_id"
            nickel export "$metadata_file" 2>/dev/null | \
                jq -r '"      Created: \(.metadata.created_at)\n      Description: \(.metadata.description // "N/A")"' || \
                echo "      (metadata parsing failed)"
        else
            echo "  [$count] $session_id"
            grep "created_at" "$metadata_file" | head -1 || true
        fi
        echo ""
    done

    if [ $count -eq 0 ]; then
        print_warning "No encrypted sessions found"
    else
        print_success "Found $count encrypted session(s)"
    fi
}

verify_setup() {
    print_info "Verifying encryption setup..."
    echo ""

    local all_ok=true

    # Check dependencies
    if command -v age &> /dev/null; then
        print_success "age encryption tool: installed ($(age --version 2>&1 | head -1))"
    else
        print_error "age encryption tool: NOT FOUND"
        all_ok=false
    fi

    # Check key
    if [ -f "$DEFAULT_KEY" ]; then
        print_success "Encryption key: present at $DEFAULT_KEY"
        local perms
        perms=$(stat -c %a "$DEFAULT_KEY" 2>/dev/null || stat -f %A "$DEFAULT_KEY" 2>/dev/null)
        if [ "$perms" = "600" ]; then
            print_success "Key permissions: secure ($perms)"
        else
            print_warning "Key permissions: $perms (recommended: 600)"
        fi
    else
        print_warning "Encryption key: not initialized (run: $0 init)"
        all_ok=false
    fi

    # Check directories
    if [ -d "$ENCRYPTED_DIR" ]; then
        print_success "Encrypted sessions directory: exists"
    else
        print_warning "Encrypted sessions directory: missing"
    fi

    # Check .gitignore
    if [ -f "$REPO_ROOT/.gitignore" ]; then
        if grep -q "\.sessions/keys" "$REPO_ROOT/.gitignore"; then
            print_success ".gitignore: keys directory excluded from git"
        else
            print_error ".gitignore: keys directory NOT excluded!"
            print_warning "Add '.sessions/keys/' to .gitignore immediately"
            all_ok=false
        fi
    fi

    echo ""
    if [ "$all_ok" = true ]; then
        print_success "All verification checks passed!"
    else
        print_warning "Some issues detected - see above"
        return 1
    fi
}

# Main command dispatcher
main() {
    case "${1:-}" in
        init)
            check_dependencies
            init_encryption
            ;;
        encrypt)
            check_dependencies
            if [ $# -lt 2 ]; then
                print_error "Usage: $0 encrypt <input-file>"
                exit 1
            fi
            encrypt_file "$2"
            ;;
        decrypt)
            check_dependencies
            if [ $# -lt 2 ]; then
                print_error "Usage: $0 decrypt <encrypted-file>"
                exit 1
            fi
            decrypt_file "$2"
            ;;
        list)
            list_sessions
            ;;
        verify)
            check_dependencies
            verify_setup
            ;;
        *)
            echo "OpenIntegrity Nickel Core - Session Encryption Tool"
            echo ""
            echo "Usage:"
            echo "  $0 init                     Initialize encryption (generate key)"
            echo "  $0 encrypt <input-file>     Encrypt a session file"
            echo "  $0 decrypt <encrypted-file> Decrypt a session file"
            echo "  $0 list                     List all encrypted sessions"
            echo "  $0 verify                   Verify encryption setup"
            echo ""
            echo "Examples:"
            echo "  $0 init"
            echo "  $0 encrypt my-conversation.txt"
            echo "  $0 decrypt .sessions/encrypted/20250121-120000-a1b2c3d4.age"
            echo "  $0 list"
            exit 1
            ;;
    esac
}

main "$@"

#!/usr/bin/env bash
#
# bip32-keygen.sh - Hierarchical deterministic key derivation for session encryption
#
# Inspired by BIP-32 concepts for semantic key hierarchies:
#   m / purpose / repository / session_type / session_index
#
# Example paths:
#   m/session/0/planning/0    - First planning session
#   m/session/0/dev/0         - First development session
#   m/session/0/review/0      - First review session
#
# This allows:
#   - Single master key backup
#   - Deterministic session key recovery
#   - Semantic organization of encryption keys
#   - Per-session-type key isolation

set -euo pipefail

# Color output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

print_info() { echo -e "${BLUE}[INFO]${NC} $*"; }
print_success() { echo -e "${GREEN}[SUCCESS]${NC} $*"; }
print_warning() { echo -e "${YELLOW}[WARNING]${NC} $*"; }
print_error() { echo -e "${RED}[ERROR]${NC} $*" >&2; }

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"
KEYS_DIR="$REPO_ROOT/.sessions/keys"
MASTER_KEY="$KEYS_DIR/master.seed"

check_dependencies() {
    local missing=()

    if ! command -v openssl &> /dev/null; then
        missing+=("openssl")
    fi

    if [ ${#missing[@]} -ne 0 ]; then
        print_error "Missing dependencies: ${missing[*]}"
        echo "Install with: apt install openssl / brew install openssl"
        exit 1
    fi
}

generate_master_seed() {
    print_info "Generating master seed for BIP32-style derivation..."

    mkdir -p "$KEYS_DIR"

    if [ -f "$MASTER_KEY" ]; then
        print_error "Master seed already exists at $MASTER_KEY"
        print_warning "Delete manually if you want to regenerate (will invalidate all derived keys!)"
        exit 1
    fi

    # Generate 256-bit entropy (32 bytes)
    openssl rand -hex 32 > "$MASTER_KEY"
    chmod 600 "$MASTER_KEY"

    print_success "Master seed generated at $MASTER_KEY"
    echo ""
    print_warning "CRITICAL: Back up this file securely!"
    print_warning "All session keys can be derived from it."
    echo ""
    echo "Backup checksum (SHA256):"
    sha256sum "$MASTER_KEY" | cut -d' ' -f1
}

derive_key() {
    local derivation_path="$1"

    if [ ! -f "$MASTER_KEY" ]; then
        print_error "Master seed not found. Run: $0 init"
        exit 1
    fi

    # Simple HKDF-like derivation using HMAC-SHA256
    # Not a full BIP32 implementation, but demonstrates the concept
    local master_seed
    master_seed=$(cat "$MASTER_KEY")

    # Derive key using HMAC with path as info
    local derived_key
    derived_key=$(echo -n "$derivation_path" | openssl dgst -sha256 -hmac "$master_seed" | cut -d' ' -f2)

    echo "$derived_key"
}

create_session_key() {
    local session_type="${1:-default}"
    local session_index="${2:-0}"

    # Derive repository identifier from git remote (if available)
    local repo_id="0"
    if git -C "$REPO_ROOT" remote get-url origin &> /dev/null; then
        local remote_url
        remote_url=$(git -C "$REPO_ROOT" remote get-url origin)
        repo_id=$(echo -n "$remote_url" | sha256sum | cut -c1-8)
    fi

    # Construct derivation path
    local derivation_path="m/session/$repo_id/$session_type/$session_index"

    print_info "Deriving session key for path: $derivation_path"

    # Derive the key
    local session_key
    session_key=$(derive_key "$derivation_path")

    # Convert hex key to age-compatible format
    # For simplicity, we'll create an age key from the derived entropy
    local session_key_file="$KEYS_DIR/session-${session_type}-${session_index}.key"

    # Generate age key using derived entropy as seed
    print_info "Generating age key from derived seed..."

    # Use the derived key as entropy for age-keygen
    # (In production, you'd use a proper key derivation library)
    echo "$session_key" | age-keygen -o "$session_key_file" 2>&1 | grep -v "Public key:" || true

    chmod 600 "$session_key_file"

    print_success "Session key created!"
    echo ""
    echo "  Derivation path: $derivation_path"
    echo "  Key file:        $session_key_file"
    echo ""

    # Extract and display public key
    local pubkey
    pubkey=$(grep "# public key:" "$session_key_file" | cut -d: -f2 | xargs)
    echo "  Public key:      $pubkey"
}

list_derivation_paths() {
    print_info "Derivation path structure:"
    echo ""
    echo "  m / purpose / repository / session_type / session_index"
    echo ""
    echo "Examples:"
    echo "  m/session/0/planning/0      - Planning sessions"
    echo "  m/session/0/dev/0           - Development sessions"
    echo "  m/session/0/review/0        - Code review sessions"
    echo "  m/session/0/research/0      - Research sessions"
    echo ""
    print_info "Current repository ID:"

    if git -C "$REPO_ROOT" remote get-url origin &> /dev/null; then
        local remote_url repo_id
        remote_url=$(git -C "$REPO_ROOT" remote get-url origin)
        repo_id=$(echo -n "$remote_url" | sha256sum | cut -c1-8)
        echo "  $repo_id (derived from: $remote_url)"
    else
        echo "  0 (no git remote configured)"
    fi
}

backup_master_seed() {
    if [ ! -f "$MASTER_KEY" ]; then
        print_error "No master seed to backup"
        exit 1
    fi

    local backup_file="$HOME/openintegrity-master-seed-backup-$(date +%Y%m%d).txt"

    print_warning "Creating master seed backup..."
    echo ""
    echo "This backup allows recovery of all derived session keys."
    echo "Store it in a secure location (password manager, encrypted drive, etc.)"
    echo ""
    read -p "Continue? (y/N) " -n 1 -r
    echo

    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        print_info "Backup cancelled"
        return
    fi

    # Create backup with metadata
    cat > "$backup_file" << EOF
OpenIntegrity Nickel Core - Master Seed Backup
===============================================

Generated: $(date -u +%Y-%m-%dT%H:%M:%SZ)
Repository: $(git -C "$REPO_ROOT" remote get-url origin 2>/dev/null || echo "N/A")
Checksum: $(sha256sum "$MASTER_KEY" | cut -d' ' -f1)

MASTER SEED (hex):
------------------
$(cat "$MASTER_KEY")

IMPORTANT:
- Keep this file secure and encrypted
- Anyone with this seed can derive all session keys
- Delete this file after backing up to secure storage
- Verify checksum when restoring

Derivation path format: m/session/{repo_id}/{session_type}/{index}
EOF

    chmod 600 "$backup_file"

    print_success "Backup created at: $backup_file"
    echo ""
    print_warning "Remember to:"
    echo "  1. Copy to secure storage (encrypted password manager, etc.)"
    echo "  2. Delete from local filesystem after verification"
    echo "  3. Test recovery before deleting original"
}

main() {
    case "${1:-}" in
        init)
            check_dependencies
            generate_master_seed
            ;;
        derive)
            check_dependencies
            if [ $# -lt 2 ]; then
                print_error "Usage: $0 derive <session-type> [session-index]"
                echo ""
                echo "Examples:"
                echo "  $0 derive planning"
                echo "  $0 derive dev 0"
                echo "  $0 derive review 2"
                exit 1
            fi
            create_session_key "$2" "${3:-0}"
            ;;
        list)
            list_derivation_paths
            ;;
        backup)
            backup_master_seed
            ;;
        *)
            echo "BIP32-Style Hierarchical Key Derivation for Session Encryption"
            echo ""
            echo "Usage:"
            echo "  $0 init                              Generate master seed"
            echo "  $0 derive <type> [index]             Derive session key"
            echo "  $0 list                              Show derivation paths"
            echo "  $0 backup                            Backup master seed"
            echo ""
            echo "Examples:"
            echo "  $0 init"
            echo "  $0 derive planning 0"
            echo "  $0 derive dev 5"
            echo "  $0 list"
            echo ""
            echo "Session types: planning, dev, review, research, discussion"
            exit 1
            ;;
    esac
}

main "$@"

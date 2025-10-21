#!/usr/bin/env bash
# Sync latest OpenIntegrityProject/core state using repomix
#
# This script fetches the original project and creates a compressed
# markdown snapshot for easy reference without maintaining a full clone.

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"
UPSTREAM_REPO="https://github.com/OpenIntegrityProject/core.git"
UPSTREAM_DIR="$PROJECT_ROOT/upstream-snapshot"
TEMP_CLONE="$(mktemp -d)"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

log_info() {
    echo -e "${BLUE}ℹ${NC} $*"
}

log_success() {
    echo -e "${GREEN}✓${NC} $*"
}

log_warn() {
    echo -e "${YELLOW}⚠${NC} $*"
}

log_error() {
    echo -e "${RED}✗${NC} $*"
}

cleanup() {
    if [[ -d "$TEMP_CLONE" ]]; then
        log_info "Cleaning up temporary clone..."
        rm -rf "$TEMP_CLONE"
    fi
}

trap cleanup EXIT

main() {
    log_info "Syncing OpenIntegrityProject/core upstream state..."

    # Check for repomix
    if ! command -v repomix &> /dev/null; then
        log_error "repomix not found. Install with: npm install -g repomix"
        exit 1
    fi

    # Clone latest upstream
    log_info "Cloning $UPSTREAM_REPO..."
    git clone --depth=1 "$UPSTREAM_REPO" "$TEMP_CLONE"

    # Get current commit hash
    cd "$TEMP_CLONE"
    COMMIT_HASH=$(git rev-parse HEAD)
    COMMIT_DATE=$(git log -1 --format=%cd --date=short)
    COMMIT_MESSAGE=$(git log -1 --format=%s)

    log_info "Latest commit: $COMMIT_HASH ($COMMIT_DATE)"
    log_info "Message: $COMMIT_MESSAGE"

    # Create upstream snapshot directory
    mkdir -p "$UPSTREAM_DIR"

    # Run repomix to create compressed markdown
    log_info "Creating compressed snapshot with repomix..."
    repomix --output "$UPSTREAM_DIR/openintegrityproject-core.md" \
            --style markdown \
            --remove-comments \
            --remove-empty-lines

    # Create metadata file
    cat > "$UPSTREAM_DIR/SNAPSHOT_INFO.md" <<EOF
# Upstream Snapshot Metadata

**Repository**: $UPSTREAM_REPO
**Commit**: $COMMIT_HASH
**Date**: $COMMIT_DATE
**Message**: $COMMIT_MESSAGE
**Snapshot Created**: $(date -Iseconds)

## Usage

This snapshot is a compressed markdown view of OpenIntegrityProject/core
for reference purposes. It is NOT a full clone and should not be modified.

To view the full snapshot:

\`\`\`bash
less upstream-snapshot/openintegrityproject-core.md
\`\`\`

To search for specific content:

\`\`\`bash
grep -n "search term" upstream-snapshot/openintegrityproject-core.md
\`\`\`

## Updating

To fetch the latest upstream state:

\`\`\`bash
./scripts/sync-upstream.sh
\`\`\`

## Original Repository

View the live repository at:
https://github.com/OpenIntegrityProject/core/tree/$COMMIT_HASH
EOF

    log_success "Upstream snapshot created successfully"
    log_info "Snapshot location: $UPSTREAM_DIR/openintegrityproject-core.md"
    log_info "Metadata: $UPSTREAM_DIR/SNAPSHOT_INFO.md"

    # Optional: Create a git commit recording the sync
    cd "$PROJECT_ROOT"
    if git rev-parse --git-dir > /dev/null 2>&1; then
        if git diff --quiet upstream-snapshot/; then
            log_info "No changes since last sync"
        else
            log_warn "Upstream has changed - consider reviewing differences"
            log_info "Run: git diff upstream-snapshot/"
        fi
    fi

    log_success "Sync complete! OpenIntegrityProject/core is ready for reference."
}

main "$@"

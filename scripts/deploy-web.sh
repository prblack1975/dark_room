#!/bin/bash
# GitHub Pages deployment script for web builds
# Usage: ./deploy-web.sh [options]
# Options:
#   --build-type=debug|release     Build type (default: release)
#   --base-href=<path>             Base href for GitHub Pages
#   --branch=<branch>              Target branch for deployment (default: gh-pages)
#   --force                        Force push to deployment branch
#   --dry-run                      Show what would be done without executing

set -e

# Configuration
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$(dirname "$SCRIPT_DIR")"
BUILD_TYPE="release"
DEPLOY_BRANCH="gh-pages"
BASE_HREF=""
FORCE_PUSH=false
DRY_RUN=false
TEMP_DIR=""

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
NC='\033[0m' # No Color

log_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

log_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

log_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

log_deploy() {
    echo -e "${PURPLE}[DEPLOY]${NC} $1"
}

# Cleanup function
cleanup() {
    if [[ -n "$TEMP_DIR" && -d "$TEMP_DIR" ]]; then
        rm -rf "$TEMP_DIR"
        log_info "Cleaned up temporary directory"
    fi
}

# Set up cleanup trap
trap cleanup EXIT

# Parse command line arguments
parse_args() {
    for arg in "$@"; do
        case $arg in
            --build-type=*)
                BUILD_TYPE="${arg#*=}"
                ;;
            --base-href=*)
                BASE_HREF="${arg#*=}"
                ;;
            --branch=*)
                DEPLOY_BRANCH="${arg#*=}"
                ;;
            --force)
                FORCE_PUSH=true
                ;;
            --dry-run)
                DRY_RUN=true
                ;;
            --help|-h)
                show_help
                exit 0
                ;;
            *)
                log_warning "Unknown argument: $arg"
                ;;
        esac
    done
}

show_help() {
    cat << EOF
Dark Room Game - GitHub Pages Deployment

Usage: $0 [options]

Options:
  --build-type=TYPE         Build type: debug or release (default: release)
  
  --base-href=PATH          Base href for GitHub Pages deployment
                           For user/org sites: --base-href=/
                           For project sites: --base-href=/repository-name/
  
  --branch=BRANCH          Target branch for deployment (default: gh-pages)
  
  --force                  Force push to deployment branch (overwrites history)
  
  --dry-run                Show what would be done without executing
  
  --help, -h               Show this help message

Examples:
  $0                                           # Deploy release build to gh-pages
  $0 --build-type=debug                        # Deploy debug build
  $0 --base-href=/dark-room-game/              # Deploy with custom base href
  $0 --force --branch=gh-pages                 # Force deploy to gh-pages
  $0 --dry-run                                 # Preview deployment without executing

GitHub Pages Setup:
1. Enable GitHub Pages in repository settings
2. Set source to deploy from branch (gh-pages)
3. Optional: Set custom domain in repository settings

Notes:
- This script builds the web version and deploys to GitHub Pages
- Requires git repository with remote origin
- Creates deployment branch if it doesn't exist
- Preserves deployment history unless --force is used

EOF
}

# Validate build type
validate_build_type() {
    if [[ "$BUILD_TYPE" != "debug" && "$BUILD_TYPE" != "release" ]]; then
        log_error "Invalid build type: $BUILD_TYPE. Use 'debug' or 'release'"
        exit 1
    fi
}

# Check git repository
check_git_repo() {
    if ! git rev-parse --git-dir > /dev/null 2>&1; then
        log_error "Not in a git repository"
        exit 1
    fi
    
    # Check for remote origin
    if ! git remote get-url origin > /dev/null 2>&1; then
        log_error "No remote origin found. Add remote origin first"
        exit 1
    fi
    
    local remote_url=$(git remote get-url origin)
    log_info "Remote origin: $remote_url"
    
    # Check if we can push to remote
    if ! git ls-remote origin > /dev/null 2>&1; then
        log_error "Cannot access remote repository. Check credentials and network"
        exit 1
    fi
    
    log_success "Git repository checks passed"
}

# Detect base href from git remote
detect_base_href() {
    if [[ -n "$BASE_HREF" ]]; then
        log_info "Using provided base href: $BASE_HREF"
        return
    fi
    
    local remote_url=$(git remote get-url origin)
    
    # Extract repository name from GitHub URL
    if [[ "$remote_url" =~ github\.com[:/]([^/]+)/([^/]+)(\.git)?$ ]]; then
        local user_or_org="${BASH_REMATCH[1]}"
        local repo_name="${BASH_REMATCH[2]}"
        repo_name="${repo_name%.git}"  # Remove .git suffix if present
        
        # Check if this is a user/organization site (username.github.io)
        if [[ "$repo_name" == "$user_or_org.github.io" ]]; then
            BASE_HREF="/"
            log_info "Detected user/organization GitHub Pages site: $BASE_HREF"
        else
            BASE_HREF="/$repo_name/"
            log_info "Detected project GitHub Pages site: $BASE_HREF"
        fi
    else
        log_warning "Could not detect base href from remote URL: $remote_url"
        BASE_HREF="/"
        log_info "Using default base href: $BASE_HREF"
    fi
}

# Build web application
build_web_app() {
    log_info "Building web application ($BUILD_TYPE)..."
    
    cd "$PROJECT_DIR"
    
    local build_args="$BUILD_TYPE"
    if [[ -n "$BASE_HREF" ]]; then
        build_args="$build_args --base-href=$BASE_HREF"
    fi
    
    if [[ "$DRY_RUN" == true ]]; then
        log_info "[DRY RUN] Would execute: ./scripts/build-web.sh $build_args"
        return 0
    fi
    
    # Execute web build
    if ! "$SCRIPT_DIR/build-web.sh" $build_args; then
        log_error "Web build failed"
        exit 1
    fi
    
    # Verify build output
    local build_output="$PROJECT_DIR/dist/web"
    if [[ ! -d "$build_output" ]] || [[ ! -f "$build_output/index.html" ]]; then
        log_error "Web build output not found or incomplete: $build_output"
        exit 1
    fi
    
    log_success "Web build completed successfully"
}

# Prepare deployment
prepare_deployment() {
    log_deploy "Preparing deployment to branch: $DEPLOY_BRANCH"
    
    # Create temporary directory for deployment
    TEMP_DIR=$(mktemp -d)
    log_info "Using temporary directory: $TEMP_DIR"
    
    # Clone the repository to temp directory
    cd "$TEMP_DIR"
    
    if [[ "$DRY_RUN" == true ]]; then
        log_info "[DRY RUN] Would clone repository for deployment preparation"
        return 0
    fi
    
    git clone "$PROJECT_DIR" deployment-repo
    cd deployment-repo
    
    # Check if deployment branch exists
    if git ls-remote --heads origin "$DEPLOY_BRANCH" | grep -q "$DEPLOY_BRANCH"; then
        log_info "Deployment branch exists, checking out..."
        git checkout "$DEPLOY_BRANCH"
    else
        log_info "Creating new deployment branch: $DEPLOY_BRANCH"
        git checkout --orphan "$DEPLOY_BRANCH"
        git rm -rf . 2>/dev/null || true
    fi
    
    # Clean the branch (preserve .git)
    find . -not -path "./.git*" -delete 2>/dev/null || true
    
    log_success "Deployment preparation completed"
}

# Copy build artifacts
copy_build_artifacts() {
    log_deploy "Copying build artifacts..."
    
    if [[ "$DRY_RUN" == true ]]; then
        log_info "[DRY RUN] Would copy build artifacts to deployment branch"
        return 0
    fi
    
    local build_output="$PROJECT_DIR/dist/web"
    local deploy_dir="$TEMP_DIR/deployment-repo"
    
    # Copy all web build files
    cp -r "$build_output"/* "$deploy_dir/"
    
    # Create .nojekyll file to prevent Jekyll processing
    touch "$deploy_dir/.nojekyll"
    
    # Create CNAME file if custom domain is configured
    if [[ -f "$PROJECT_DIR/CNAME" ]]; then
        cp "$PROJECT_DIR/CNAME" "$deploy_dir/CNAME"
        log_info "Copied CNAME file for custom domain"
    fi
    
    # Create deployment info file
    local deploy_info_file="$deploy_dir/.deployment-info.json"
    local deploy_time=$(date -u +"%Y-%m-%dT%H:%M:%SZ")
    local commit_hash=$(cd "$PROJECT_DIR" && git rev-parse HEAD)
    local version=$(cd "$PROJECT_DIR" && grep "version:" pubspec.yaml | sed 's/version: //' | tr -d ' ')
    
    cat > "$deploy_info_file" << EOF
{
  "deploymentTime": "$deploy_time",
  "sourceCommit": "$commit_hash",
  "version": "$version",
  "buildType": "$BUILD_TYPE",
  "baseHref": "$BASE_HREF",
  "deploymentBranch": "$DEPLOY_BRANCH"
}
EOF
    
    log_success "Build artifacts copied successfully"
}

# Create deployment commit
create_deployment_commit() {
    log_deploy "Creating deployment commit..."
    
    if [[ "$DRY_RUN" == true ]]; then
        log_info "[DRY RUN] Would create deployment commit and push to $DEPLOY_BRANCH"
        return 0
    fi
    
    cd "$TEMP_DIR/deployment-repo"
    
    # Configure git user if not already configured
    if ! git config user.name > /dev/null 2>&1; then
        git config user.name "GitHub Pages Deployment"
        git config user.email "noreply@github.com"
    fi
    
    # Add all files
    git add .
    
    # Check if there are changes to commit
    if git diff --cached --quiet; then
        log_info "No changes to deploy"
        return 0
    fi
    
    # Create commit message
    local source_commit_short=$(cd "$PROJECT_DIR" && git rev-parse --short HEAD)
    local version=$(cd "$PROJECT_DIR" && grep "version:" pubspec.yaml | sed 's/version: //' | tr -d ' ')
    local commit_message="Deploy Dark Room Game v$version ($BUILD_TYPE)

Source commit: $source_commit_short
Build type: $BUILD_TYPE
Base href: $BASE_HREF
Deployment time: $(date -u +"%Y-%m-%d %H:%M:%S UTC")"
    
    # Commit changes
    git commit -m "$commit_message"
    
    log_success "Deployment commit created"
}

# Push to GitHub
push_to_github() {
    log_deploy "Pushing to GitHub Pages..."
    
    if [[ "$DRY_RUN" == true ]]; then
        log_info "[DRY RUN] Would push deployment to origin/$DEPLOY_BRANCH"
        return 0
    fi
    
    cd "$TEMP_DIR/deployment-repo"
    
    # Push to remote
    local push_args="origin $DEPLOY_BRANCH"
    if [[ "$FORCE_PUSH" == true ]]; then
        push_args="--force $push_args"
        log_warning "Force pushing to deployment branch (will overwrite history)"
    fi
    
    if git push $push_args; then
        log_success "Successfully pushed to GitHub Pages"
    else
        log_error "Failed to push to GitHub Pages"
        exit 1
    fi
}

# Get deployment URL
get_deployment_url() {
    local remote_url=$(git remote get-url origin)
    
    if [[ "$remote_url" =~ github\.com[:/]([^/]+)/([^/]+)(\.git)?$ ]]; then
        local user_or_org="${BASH_REMATCH[1]}"
        local repo_name="${BASH_REMATCH[2]}"
        repo_name="${repo_name%.git}"
        
        if [[ "$repo_name" == "$user_or_org.github.io" ]]; then
            echo "https://$user_or_org.github.io"
        else
            echo "https://$user_or_org.github.io/$repo_name"
        fi
    else
        echo "Could not determine deployment URL"
    fi
}

# Show deployment summary
show_deployment_summary() {
    echo
    log_success "=== DEPLOYMENT SUMMARY ==="
    
    local deployment_url=$(get_deployment_url)
    local version=$(cd "$PROJECT_DIR" && grep "version:" pubspec.yaml | sed 's/version: //' | tr -d ' ')
    
    log_info "Version deployed: $version"
    log_info "Build type: $BUILD_TYPE"
    log_info "Base href: $BASE_HREF"
    log_info "Target branch: $DEPLOY_BRANCH"
    log_info "Deployment URL: $deployment_url"
    
    if [[ "$DRY_RUN" != true ]]; then
        echo
        log_info "GitHub Pages deployment may take a few minutes to become available"
        log_info "Check the repository's Pages settings and Actions tab for deployment status"
        
        echo
        log_info "Next steps:"
        log_info "1. Wait for GitHub Pages deployment to complete"
        log_info "2. Visit $deployment_url to test the deployed game"
        log_info "3. Configure custom domain in repository settings if needed"
    fi
}

# Main execution
main() {
    echo "Dark Room Game - GitHub Pages Deployment"
    echo "========================================"
    echo
    
    # Parse arguments
    parse_args "$@"
    
    # Validate inputs
    validate_build_type
    
    if [[ "$DRY_RUN" == true ]]; then
        log_warning "DRY RUN MODE - No actual changes will be made"
        echo
    fi
    
    # Pre-deployment checks
    check_git_repo
    detect_base_href
    
    # Build and deploy
    build_web_app
    prepare_deployment
    copy_build_artifacts
    create_deployment_commit
    push_to_github
    
    # Show results
    show_deployment_summary
    
    if [[ "$DRY_RUN" != true ]]; then
        log_success "GitHub Pages deployment completed successfully!"
    else
        log_info "Dry run completed - use without --dry-run to actually deploy"
    fi
}

# Execute main function
main "$@"
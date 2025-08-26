#!/bin/bash
# Main deployment orchestration script
# Usage: ./deploy.sh [options]

set -e

# Configuration
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$(dirname "$SCRIPT_DIR")"

# Default options
DEPLOY_WEB=true
CREATE_RELEASE=true
BUILD_TYPE="release"
PRERELEASE=false
DRAFT=false
FORCE_WEB=false
VERSION=""

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

# Parse command line arguments
parse_args() {
    for arg in "$@"; do
        case $arg in
            --build-type=*)
                BUILD_TYPE="${arg#*=}"
                ;;
            --version=*)
                VERSION="${arg#*=}"
                ;;
            --prerelease)
                PRERELEASE=true
                ;;
            --draft)
                DRAFT=true
                ;;
            --web-only)
                CREATE_RELEASE=false
                ;;
            --release-only)
                DEPLOY_WEB=false
                ;;
            --force-web)
                FORCE_WEB=true
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
Dark Room Game - Deployment Orchestration Script

Usage: $0 [options]

Options:
  --build-type=TYPE         Build type: debug or release (default: release)
  --version=VERSION         Version to deploy (auto-detected if not specified)
  --prerelease              Mark GitHub release as pre-release
  --draft                   Create GitHub release as draft
  --web-only                Deploy only to GitHub Pages (skip release creation)
  --release-only            Create only GitHub release (skip web deployment)
  --force-web               Force push to GitHub Pages deployment branch
  --help, -h                Show this help message

Default Behavior:
  - Builds all platforms for release
  - Deploys web version to GitHub Pages
  - Creates GitHub release with all platform builds
  - Increments version build number automatically

Examples:
  $0                                    # Full deployment (web + release)
  $0 --web-only                         # Deploy only to GitHub Pages
  $0 --release-only --draft             # Create draft GitHub release only
  $0 --version=1.2.3 --prerelease       # Deploy specific version as pre-release
  $0 --build-type=debug --web-only      # Deploy debug build to web only

Deployment Process:
  1. Environment validation and dependency checks
  2. Version management (increment build number for release)
  3. Build all platforms
  4. Deploy web version to GitHub Pages (if enabled)
  5. Create GitHub release with all assets (if enabled)
  6. Generate deployment report

Prerequisites:
  - Git repository with GitHub remote
  - GitHub CLI (gh) installed and authenticated (for releases)
  - Flutter development environment properly set up

EOF
}

# Validate environment
validate_environment() {
    log_info "Validating deployment environment..."
    
    # Run environment check
    local env_check_script="$SCRIPT_DIR/check-build-env.sh"
    if [[ -f "$env_check_script" ]]; then
        if "$env_check_script" --platforms=web,android,ios,macos,linux,windows; then
            log_success "Environment validation passed"
        else
            log_warning "Some environment checks failed, but continuing..."
        fi
    else
        log_warning "Environment check script not found, skipping validation"
    fi
}

# Manage version
manage_version() {
    local version_script="$SCRIPT_DIR/version-manager.sh"
    
    if [[ ! -f "$version_script" ]]; then
        log_error "Version manager script not found: $version_script"
        exit 1
    fi
    
    # Set specific version if provided
    if [[ -n "$VERSION" ]]; then
        log_info "Setting version to: $VERSION"
        "$version_script" set "$VERSION"
    fi
    
    # Increment build number for release builds
    if [[ "$BUILD_TYPE" == "release" ]]; then
        log_info "Incrementing build number for release build"
        "$version_script" pre-build-increment "release"
    fi
    
    # Show current version
    local current_version=$("$version_script" current | grep "Full version:" | cut -d':' -f2 | tr -d ' ')
    log_info "Deploying version: $current_version"
    
    return 0
}

# Build all platforms
build_platforms() {
    log_deploy "Building all platforms..."
    
    local build_script="$SCRIPT_DIR/build-all.sh"
    if [[ ! -f "$build_script" ]]; then
        log_error "Build orchestration script not found: $build_script"
        exit 1
    fi
    
    local build_args="--build-type=$BUILD_TYPE --clean"
    
    if "$build_script" $build_args; then
        log_success "All platform builds completed successfully"
    else
        log_error "Platform builds failed"
        exit 1
    fi
}

# Deploy to GitHub Pages
deploy_github_pages() {
    if [[ "$DEPLOY_WEB" != true ]]; then
        log_info "Skipping GitHub Pages deployment (--release-only specified)"
        return 0
    fi
    
    log_deploy "Deploying to GitHub Pages..."
    
    local web_deploy_script="$SCRIPT_DIR/deploy-web.sh"
    if [[ ! -f "$web_deploy_script" ]]; then
        log_error "Web deployment script not found: $web_deploy_script"
        exit 1
    fi
    
    local deploy_args="--build-type=$BUILD_TYPE"
    if [[ "$FORCE_WEB" == true ]]; then
        deploy_args="$deploy_args --force"
    fi
    
    if "$web_deploy_script" $deploy_args; then
        log_success "GitHub Pages deployment completed"
    else
        log_error "GitHub Pages deployment failed"
        exit 1
    fi
}

# Create GitHub release
create_github_release() {
    if [[ "$CREATE_RELEASE" != true ]]; then
        log_info "Skipping GitHub release creation (--web-only specified)"
        return 0
    fi
    
    log_deploy "Creating GitHub release..."
    
    local release_script="$SCRIPT_DIR/release-manager.sh"
    if [[ ! -f "$release_script" ]]; then
        log_error "Release manager script not found: $release_script"
        exit 1
    fi
    
    local release_args="--generate-notes"
    
    if [[ -n "$VERSION" ]]; then
        release_args="$release_args --version=$VERSION"
    fi
    
    if [[ "$PRERELEASE" == true ]]; then
        release_args="$release_args --prerelease"
    fi
    
    if [[ "$DRAFT" == true ]]; then
        release_args="$release_args --draft"
    fi
    
    if "$release_script" create-release $release_args; then
        log_success "GitHub release created successfully"
    else
        log_error "GitHub release creation failed"
        exit 1
    fi
}

# Generate deployment report
generate_deployment_report() {
    local report_file="$PROJECT_DIR/deployment-report.json"
    local deploy_time=$(date -u +"%Y-%m-%dT%H:%M:%SZ")
    local commit_hash=$(git rev-parse HEAD)
    local version_script="$SCRIPT_DIR/version-manager.sh"
    local current_version="unknown"
    
    if [[ -f "$version_script" ]]; then
        current_version=$("$version_script" current | grep "Full version:" | cut -d':' -f2 | tr -d ' ' || echo "unknown")
    fi
    
    # Get repository information
    local repo_info=""
    if command -v gh &> /dev/null && gh auth status &> /dev/null; then
        repo_info=$(gh repo view --json owner,name 2>/dev/null || echo '{"owner":{"login":"unknown"},"name":"unknown"}')
    else
        repo_info='{"owner":{"login":"unknown"},"name":"unknown"}'
    fi
    
    local owner=$(echo "$repo_info" | jq -r '.owner.login' 2>/dev/null || echo "unknown")
    local repo_name=$(echo "$repo_info" | jq -r '.name' 2>/dev/null || echo "unknown")
    
    # Generate report
    cat > "$report_file" << EOF
{
  "deploymentTime": "$deploy_time",
  "version": "$current_version",
  "buildType": "$BUILD_TYPE",
  "commitHash": "$commit_hash",
  "deployedComponents": {
    "githubPages": $DEPLOY_WEB,
    "githubRelease": $CREATE_RELEASE
  },
  "repository": {
    "owner": "$owner",
    "name": "$repo_name"
  },
  "urls": {
    "githubPages": "https://$owner.github.io/$repo_name",
    "release": "https://github.com/$owner/$repo_name/releases/tag/v${current_version%+*}",
    "repository": "https://github.com/$owner/$repo_name"
  },
  "buildArtifacts": "$(find "$PROJECT_DIR/dist" -type f -name "*.apk" -o -name "*.aab" -o -name "*.tar.gz" -o -name "*.zip" | wc -l | tr -d ' ') files",
  "deploymentOptions": {
    "prerelease": $PRERELEASE,
    "draft": $DRAFT,
    "forceWeb": $FORCE_WEB
  }
}
EOF
    
    log_success "Deployment report generated: $report_file"
}

# Show deployment summary
show_deployment_summary() {
    echo
    log_success "=== DEPLOYMENT COMPLETED SUCCESSFULLY ==="
    echo
    
    local version_script="$SCRIPT_DIR/version-manager.sh"
    local current_version="unknown"
    
    if [[ -f "$version_script" ]]; then
        current_version=$("$version_script" current | grep "Full version:" | cut -d':' -f2 | tr -d ' ' || echo "unknown")
    fi
    
    log_info "Version deployed: $current_version"
    log_info "Build type: $BUILD_TYPE"
    
    if [[ "$DEPLOY_WEB" == true ]]; then
        # Get deployment URL
        local remote_url=$(git remote get-url origin)
        if [[ "$remote_url" =~ github\.com[:/]([^/]+)/([^/]+)(\.git)?$ ]]; then
            local user_or_org="${BASH_REMATCH[1]}"
            local repo_name="${BASH_REMATCH[2]}"
            repo_name="${repo_name%.git}"
            
            local pages_url="https://$user_or_org.github.io/$repo_name"
            log_info "🌐 Web deployment: $pages_url"
        fi
    fi
    
    if [[ "$CREATE_RELEASE" == true ]]; then
        local remote_url=$(git remote get-url origin)
        if [[ "$remote_url" =~ github\.com[:/]([^/]+)/([^/]+)(\.git)?$ ]]; then
            local user_or_org="${BASH_REMATCH[1]}"
            local repo_name="${BASH_REMATCH[2]}"
            repo_name="${repo_name%.git}"
            
            local version_tag="v${current_version%+*}"
            local release_url="https://github.com/$user_or_org/$repo_name/releases/tag/$version_tag"
            log_info "🚀 GitHub release: $release_url"
        fi
    fi
    
    echo
    log_info "📊 Build artifacts available in: $PROJECT_DIR/dist"
    log_info "📋 Deployment report: $PROJECT_DIR/deployment-report.json"
    
    echo
    log_info "Next steps:"
    if [[ "$DEPLOY_WEB" == true ]]; then
        log_info "1. Wait a few minutes for GitHub Pages to update"
        log_info "2. Test the web deployment"
    fi
    if [[ "$CREATE_RELEASE" == true ]]; then
        log_info "3. Review the GitHub release and assets"
        log_info "4. Share the release with your users"
    fi
    
    echo
    log_success "🎉 Dark Room Game deployment completed!"
}

# Main execution
main() {
    echo "Dark Room Game - Deployment Orchestration"
    echo "========================================="
    echo
    
    # Parse arguments
    parse_args "$@"
    
    # Validate build type
    if [[ "$BUILD_TYPE" != "debug" && "$BUILD_TYPE" != "release" ]]; then
        log_error "Invalid build type: $BUILD_TYPE. Use 'debug' or 'release'"
        exit 1
    fi
    
    # Show deployment plan
    log_info "Deployment Plan:"
    log_info "- Build type: $BUILD_TYPE"
    log_info "- GitHub Pages: $DEPLOY_WEB"
    log_info "- GitHub Release: $CREATE_RELEASE"
    if [[ -n "$VERSION" ]]; then
        log_info "- Target version: $VERSION"
    fi
    if [[ "$PRERELEASE" == true ]]; then
        log_info "- Pre-release: true"
    fi
    if [[ "$DRAFT" == true ]]; then
        log_info "- Draft release: true"
    fi
    echo
    
    # Confirm deployment
    if [[ "$BUILD_TYPE" == "release" ]]; then
        read -p "Proceed with deployment? (Y/n): " -n 1 -r
        echo
        if [[ $REPLY =~ ^[Nn]$ ]]; then
            log_info "Deployment cancelled"
            exit 0
        fi
    fi
    
    cd "$PROJECT_DIR"
    
    # Execute deployment steps
    validate_environment
    manage_version
    build_platforms
    deploy_github_pages
    create_github_release
    generate_deployment_report
    show_deployment_summary
}

# Execute main function
main "$@"
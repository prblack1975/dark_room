#!/bin/bash
# Build script for Web platform
# Usage: ./build-web.sh [debug|release] [--base-href=<path>]

set -e

# Configuration
BUILD_TYPE=${1:-release}
BASE_HREF=""
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$(dirname "$SCRIPT_DIR")"
BUILD_OUTPUT_DIR="$PROJECT_DIR/dist/web"

# Parse additional arguments
for arg in "$@"; do
    case $arg in
        --base-href=*)
        BASE_HREF="${arg#*=}"
        shift
        ;;
    esac
done

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
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

# Validate build type
if [[ "$BUILD_TYPE" != "debug" && "$BUILD_TYPE" != "release" ]]; then
    log_error "Invalid build type: $BUILD_TYPE. Use 'debug' or 'release'"
    exit 1
fi

log_info "Starting Web build..."
log_info "Build type: $BUILD_TYPE"
if [[ -n "$BASE_HREF" ]]; then
    log_info "Base href: $BASE_HREF"
fi

# Change to project directory
cd "$PROJECT_DIR"

# Check Flutter web support
if ! flutter config | grep -q "enable-web: true"; then
    log_info "Enabling Flutter web support..."
    flutter config --enable-web
fi

# Clean previous builds
log_info "Cleaning previous builds..."
flutter clean

# Get dependencies
log_info "Getting dependencies..."
flutter pub get

# Run code analysis
log_info "Running code analysis..."
if ! flutter analyze --no-fatal-infos; then
    log_warning "Code analysis found issues. Continuing with build..."
fi

# Run tests (skip web-specific tests that might not work in headless mode)
log_info "Running tests..."
if ! flutter test; then
    log_warning "Some tests failed. Continuing with build..."
fi

# Create output directory
mkdir -p "$BUILD_OUTPUT_DIR"

# Build for web
log_info "Building web app ($BUILD_TYPE)..."

BUILD_ARGS=""
if [[ "$BUILD_TYPE" == "release" ]]; then
    BUILD_ARGS="--release"
else
    BUILD_ARGS="--debug"
fi

# Add base href if specified
if [[ -n "$BASE_HREF" ]]; then
    BUILD_ARGS="$BUILD_ARGS --base-href=$BASE_HREF"
fi

# Execute build
flutter build web $BUILD_ARGS

# Check if build succeeded
WEB_BUILD_PATH="$PROJECT_DIR/build/web"
if [[ ! -d "$WEB_BUILD_PATH" ]]; then
    log_error "Web build failed - output directory not found: $WEB_BUILD_PATH"
    exit 1
fi

# Copy build artifacts to dist directory
log_info "Copying build artifacts..."
rm -rf "$BUILD_OUTPUT_DIR"/*
cp -r "$WEB_BUILD_PATH"/* "$BUILD_OUTPUT_DIR/"

# Calculate build size
BUILD_SIZE=$(du -sh "$BUILD_OUTPUT_DIR" | cut -f1)

# Create optimized version for production
if [[ "$BUILD_TYPE" == "release" ]]; then
    log_info "Optimizing for production..."
    
    # Compress assets if gzip is available
    if command -v gzip &> /dev/null; then
        find "$BUILD_OUTPUT_DIR" -type f \( -name "*.js" -o -name "*.css" -o -name "*.html" -o -name "*.json" \) -exec gzip -k {} \;
        log_info "Created gzipped versions of text assets"
    fi
    
    # Create a deployment-ready archive
    ARCHIVE_NAME="dark_room-web-$BUILD_TYPE.tar.gz"
    cd "$BUILD_OUTPUT_DIR"
    tar -czf "../$ARCHIVE_NAME" *
    cd "$PROJECT_DIR"
    
    ARCHIVE_SIZE=$(du -h "$PROJECT_DIR/dist/$ARCHIVE_NAME" | cut -f1)
    log_success "Created deployment archive: $ARCHIVE_NAME ($ARCHIVE_SIZE)"
fi

# Generate build info
BUILD_INFO_FILE="$BUILD_OUTPUT_DIR/build-info.json"
VERSION=$(grep "version:" pubspec.yaml | sed 's/version: //' | tr -d ' ')
BUILD_TIME=$(date -u +"%Y-%m-%dT%H:%M:%SZ")
COMMIT_HASH=$(git rev-parse HEAD 2>/dev/null || echo "unknown")

cat > "$BUILD_INFO_FILE" << EOF
{
  "platform": "web",
  "version": "$VERSION",
  "buildType": "$BUILD_TYPE",
  "buildTime": "$BUILD_TIME",
  "commitHash": "$COMMIT_HASH",
  "baseHref": "$BASE_HREF",
  "renderer": "canvaskit",
  "dartVersion": "$(dart --version 2>&1 | cut -d' ' -f4)",
  "flutterVersion": "$(flutter --version | head -n1 | cut -d' ' -f2)",
  "buildSize": "$BUILD_SIZE"
}
EOF

# Generate deployment instructions
DEPLOY_INSTRUCTIONS="$BUILD_OUTPUT_DIR/DEPLOYMENT.md"
cat > "$DEPLOY_INSTRUCTIONS" << EOF
# Web Deployment Instructions

## Files in this directory
This directory contains a complete web build of the Dark Room game.

## Deployment Options

### 1. Static Web Hosting
Upload all files to any static web hosting service:
- GitHub Pages
- Netlify
- Vercel
- AWS S3 + CloudFront
- Any web server

### 2. Local Testing
Serve locally using Python or Node.js:
\`\`\`bash
# Using Python 3
python -m http.server 8000

# Using Python 2
python -m SimpleHTTPServer 8000

# Using Node.js (http-server)
npx http-server
\`\`\`

### 3. GitHub Pages Deployment
If deploying to GitHub Pages, ensure the base-href is set correctly:
- For user/organization pages: --base-href=/
- For project pages: --base-href=/repository-name/

## Important Notes
- All files must be served from the same domain
- HTTPS is recommended for production
- Enable gzip compression on your server for better performance
- The game requires web audio APIs (modern browser required)

## Build Information
- Version: $VERSION
- Build Type: $BUILD_TYPE
- Build Time: $BUILD_TIME
- Build Size: $BUILD_SIZE
EOF

log_success "Web build completed successfully!"
log_info "Build artifacts saved to: $BUILD_OUTPUT_DIR"
log_info "Build size: $BUILD_SIZE"
log_info "Deployment instructions: $DEPLOY_INSTRUCTIONS"

# Provide next steps
if [[ "$BUILD_TYPE" == "release" ]]; then
    log_info "Next steps for deployment:"
    log_info "1. Test locally: cd $BUILD_OUTPUT_DIR && python -m http.server 8000"
    log_info "2. Upload to your web hosting service"
    log_info "3. Or use the deployment archive: dist/$ARCHIVE_NAME"
fi
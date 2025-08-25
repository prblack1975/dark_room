#!/bin/bash
# Pre-checkin validation script
# Usage: ./pre-checkin.sh [options]
# 
# This script runs comprehensive validation before code commits:
# - Environment checks
# - Code analysis and linting
# - Test suite execution
# - Multi-platform build verification
# - Artifact validation

set -e

# Configuration
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$(dirname "$SCRIPT_DIR")"
LOG_DIR="$PROJECT_DIR/pre-checkin-logs"

# Default options
QUICK_MODE=false
SKIP_BUILDS=false
PLATFORMS="web,android,ios,macos,linux,windows"
BUILD_TYPE="debug"
PARALLEL_BUILDS=true
FIX_ISSUES=false

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
CYAN='\033[0;36m'
BOLD='\033[1m'
NC='\033[0m' # No Color

# Validation tracking
declare -a VALIDATION_RESULTS=()
declare -a FAILED_CHECKS=()
TOTAL_CHECKS=0
PASSED_CHECKS=0

log_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

log_success() {
    echo -e "${GREEN}[✓ PASS]${NC} $1"
}

log_warning() {
    echo -e "${YELLOW}[⚠ WARN]${NC} $1"
}

log_error() {
    echo -e "${RED}[✗ FAIL]${NC} $1"
}

log_check() {
    echo -e "${PURPLE}[CHECK]${NC} $1"
}

log_section() {
    echo
    echo -e "${BOLD}${CYAN}=== $1 ===${NC}"
    echo
}

# Track validation results
track_result() {
    local check_name="$1"
    local result="$2"  # "pass" or "fail"
    local details="$3"
    
    ((TOTAL_CHECKS++))
    
    if [[ "$result" == "pass" ]]; then
        ((PASSED_CHECKS++))
        VALIDATION_RESULTS+=("✓ $check_name")
        log_success "$check_name"
        if [[ -n "$details" ]]; then
            log_info "  $details"
        fi
    else
        FAILED_CHECKS+=("$check_name")
        VALIDATION_RESULTS+=("✗ $check_name")
        log_error "$check_name"
        if [[ -n "$details" ]]; then
            log_error "  $details"
        fi
    fi
}

# Parse command line arguments
parse_args() {
    for arg in "$@"; do
        case $arg in
            --quick)
                QUICK_MODE=true
                PLATFORMS="web,android"
                BUILD_TYPE="debug"
                ;;
            --skip-builds)
                SKIP_BUILDS=true
                ;;
            --platforms=*)
                PLATFORMS="${arg#*=}"
                ;;
            --build-type=*)
                BUILD_TYPE="${arg#*=}"
                ;;
            --sequential)
                PARALLEL_BUILDS=false
                ;;
            --fix)
                FIX_ISSUES=true
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
Dark Room Game - Pre-Checkin Validation Script

Usage: $0 [options]

This script performs comprehensive validation before code commits:
✓ Environment and dependency checks
✓ Code quality analysis and linting
✓ Complete test suite execution
✓ Multi-platform build verification
✓ Build artifact validation
✓ Git repository status check

Options:
  --quick                   Quick validation mode (web + Android only, debug builds)
  --skip-builds            Skip platform builds (tests and analysis only)
  --platforms=PLATFORMS    Comma-separated platforms to build (default: all)
  --build-type=TYPE        Build type: debug or release (default: debug)
  --sequential             Build platforms sequentially (default: parallel)
  --fix                    Attempt to automatically fix issues where possible
  --help, -h               Show this help message

Examples:
  $0                                    # Full validation (all platforms)
  $0 --quick                           # Quick validation (web + Android)
  $0 --skip-builds                     # Tests and analysis only
  $0 --platforms=web,android --fix     # Specific platforms with auto-fix

Validation Steps:
1. Environment Check - Verify Flutter, dependencies, and platform tools
2. Git Status Check - Ensure repository is in good state
3. Code Analysis - Flutter analyze with strict linting
4. Test Suite - Run all tests with coverage
5. Build Verification - Build specified platforms
6. Artifact Validation - Verify build outputs

Exit Codes:
  0 = All checks passed
  1 = Some checks failed (details in output)
  2 = Critical failure (cannot continue)

EOF
}

# Initialize logging
setup_logging() {
    mkdir -p "$LOG_DIR"
    local timestamp=$(date +"%Y%m%d_%H%M%S")
    export PRE_CHECKIN_LOG="$LOG_DIR/pre-checkin-$timestamp.log"
    
    # Log to both console and file
    exec 1> >(tee -a "$PRE_CHECKIN_LOG")
    exec 2> >(tee -a "$PRE_CHECKIN_LOG" >&2)
    
    log_info "Pre-checkin validation started: $(date)"
    log_info "Log file: $PRE_CHECKIN_LOG"
}

# 1. Environment validation
check_environment() {
    log_section "1. Environment Validation"
    
    local env_script="$SCRIPT_DIR/check-build-env.sh"
    if [[ -f "$env_script" ]]; then
        local fix_arg=""
        if [[ "$FIX_ISSUES" == true ]]; then
            fix_arg="--fix"
        fi
        
        if "$env_script" --platforms="$PLATFORMS" $fix_arg > /dev/null 2>&1; then
            track_result "Environment Check" "pass" "All dependencies verified"
        else
            track_result "Environment Check" "fail" "Run './scripts/check-build-env.sh --fix' to resolve"
            return 1
        fi
    else
        track_result "Environment Check" "fail" "Environment check script not found"
        return 1
    fi
}

# 2. Git repository status
check_git_status() {
    log_section "2. Git Repository Status"
    
    cd "$PROJECT_DIR"
    
    # Check if we're in a git repository
    if ! git rev-parse --git-dir > /dev/null 2>&1; then
        track_result "Git Repository" "fail" "Not in a git repository"
        return 1
    fi
    
    track_result "Git Repository" "pass" "Valid git repository"
    
    # Check for unstaged changes
    if ! git diff-files --quiet; then
        local unstaged_count=$(git diff-files --name-only | wc -l | tr -d ' ')
        track_result "Unstaged Changes" "fail" "$unstaged_count files have unstaged changes"
    else
        track_result "Unstaged Changes" "pass" "No unstaged changes"
    fi
    
    # Check for uncommitted changes
    if ! git diff-index --quiet --cached HEAD --; then
        local staged_count=$(git diff-index --cached --name-only HEAD | wc -l | tr -d ' ')
        track_result "Staged Changes" "pass" "$staged_count files staged for commit"
    else
        track_result "Staged Changes" "pass" "No staged changes (working directory clean)"
    fi
    
    # Check current branch
    local current_branch=$(git branch --show-current 2>/dev/null || echo "detached")
    track_result "Git Branch" "pass" "Current branch: $current_branch"
    
    # Check for remote tracking
    if git rev-parse --abbrev-ref --symbolic-full-name @{u} > /dev/null 2>&1; then
        local remote_branch=$(git rev-parse --abbrev-ref --symbolic-full-name @{u})
        
        # Check if ahead/behind remote
        local ahead=$(git rev-list --count @{u}..HEAD 2>/dev/null || echo "0")
        local behind=$(git rev-list --count HEAD..@{u} 2>/dev/null || echo "0")
        
        if [[ "$ahead" -gt 0 ]] || [[ "$behind" -gt 0 ]]; then
            track_result "Remote Sync" "pass" "Ahead: $ahead, Behind: $behind (from $remote_branch)"
        else
            track_result "Remote Sync" "pass" "Up to date with $remote_branch"
        fi
    else
        track_result "Remote Sync" "warn" "No remote tracking branch configured"
    fi
}

# 3. Code analysis and linting
check_code_quality() {
    log_section "3. Code Quality Analysis"
    
    cd "$PROJECT_DIR"
    
    # Get dependencies first
    log_check "Getting dependencies..."
    if flutter pub get > /dev/null 2>&1; then
        track_result "Dependencies" "pass" "Flutter pub get successful"
    else
        track_result "Dependencies" "fail" "Flutter pub get failed"
        return 1
    fi
    
    # Run Flutter analyze
    log_check "Running Flutter analyze..."
    local analyze_output=$(flutter analyze 2>&1)
    local analyze_exit_code=$?
    
    if [[ $analyze_exit_code -eq 0 ]]; then
        track_result "Flutter Analyze" "pass" "No issues found"
    else
        local issue_count=$(echo "$analyze_output" | grep -c "•" || echo "0")
        track_result "Flutter Analyze" "fail" "$issue_count issues found"
        
        # Show first few issues
        echo "$analyze_output" | head -20
        if [[ $(echo "$analyze_output" | wc -l) -gt 20 ]]; then
            log_info "... (showing first 20 lines, see full log for details)"
        fi
    fi
    
    # Check for TODO/FIXME comments
    log_check "Scanning for TODO/FIXME comments..."
    local todo_count=$(find lib test -name "*.dart" -exec grep -l "TODO\|FIXME" {} \; 2>/dev/null | wc -l | tr -d ' ')
    if [[ "$todo_count" -gt 0 ]]; then
        track_result "TODO/FIXME Comments" "warn" "$todo_count files contain TODO/FIXME comments"
    else
        track_result "TODO/FIXME Comments" "pass" "No TODO/FIXME comments found"
    fi
    
    # Check for debug print statements
    log_check "Checking for debug print statements..."
    local debug_count=$(find lib -name "*.dart" -exec grep -l "print(" {} \; 2>/dev/null | wc -l | tr -d ' ')
    if [[ "$debug_count" -gt 0 ]]; then
        track_result "Debug Prints" "warn" "$debug_count files contain print() statements"
    else
        track_result "Debug Prints" "pass" "No debug print statements found"
    fi
}

# 4. Test execution
run_tests() {
    log_section "4. Test Suite Execution"
    
    cd "$PROJECT_DIR"
    
    # Check if tests exist
    if [[ ! -d "test" ]] || [[ -z "$(find test -name "*.dart" 2>/dev/null)" ]]; then
        track_result "Test Files" "warn" "No test files found"
        return 0
    fi
    
    local test_count=$(find test -name "*.dart" | wc -l | tr -d ' ')
    track_result "Test Files" "pass" "$test_count test files found"
    
    # Run tests
    log_check "Running Flutter tests..."
    local test_output_file="$LOG_DIR/test-output-$(date +%H%M%S).log"
    local test_start_time=$(date +%s)
    
    if flutter test --coverage 2>&1 | tee "$test_output_file"; then
        local test_end_time=$(date +%s)
        local test_duration=$((test_end_time - test_start_time))
        track_result "Test Execution" "pass" "All tests passed (${test_duration}s)"
        
        # Parse test results if possible
        local test_summary=$(tail -10 "$test_output_file" | grep "All tests passed" || echo "")
        if [[ -n "$test_summary" ]]; then
            log_info "$test_summary"
        fi
        
        # Check coverage if available
        if [[ -f "coverage/lcov.info" ]]; then
            local coverage_percent="unknown"
            if command -v lcov &> /dev/null; then
                coverage_percent=$(lcov --summary coverage/lcov.info 2>&1 | grep "lines" | awk '{print $2}' || echo "unknown")
            fi
            track_result "Test Coverage" "pass" "Coverage report generated ($coverage_percent)"
        else
            track_result "Test Coverage" "warn" "No coverage report generated"
        fi
        
    else
        local test_end_time=$(date +%s)
        local test_duration=$((test_end_time - test_start_time))
        track_result "Test Execution" "fail" "Some tests failed (${test_duration}s)"
        
        # Show last part of test output for failure details
        echo
        log_error "Test failure details (last 20 lines):"
        tail -20 "$test_output_file"
        return 1
    fi
}

# 5. Build verification
verify_builds() {
    if [[ "$SKIP_BUILDS" == true ]]; then
        log_section "5. Build Verification (SKIPPED)"
        track_result "Build Verification" "pass" "Skipped per user request"
        return 0
    fi
    
    log_section "5. Multi-Platform Build Verification"
    
    local build_script="$SCRIPT_DIR/build-all.sh"
    if [[ ! -f "$build_script" ]]; then
        track_result "Build Script" "fail" "Build orchestration script not found"
        return 1
    fi
    
    track_result "Build Script" "pass" "Build orchestration script found"
    
    # Prepare build arguments
    local build_args="--build-type=$BUILD_TYPE --platforms=$PLATFORMS"
    if [[ "$PARALLEL_BUILDS" == true ]]; then
        build_args="$build_args --parallel"
    fi
    if [[ "$QUICK_MODE" == true ]]; then
        build_args="$build_args --skip-tests"  # Already ran tests above
    fi
    
    log_check "Building platforms: $PLATFORMS ($BUILD_TYPE)"
    local build_start_time=$(date +%s)
    
    if "$build_script" $build_args; then
        local build_end_time=$(date +%s)
        local build_duration=$((build_end_time - build_start_time))
        track_result "Platform Builds" "pass" "All platforms built successfully (${build_duration}s)"
    else
        local build_end_time=$(date +%s)
        local build_duration=$((build_end_time - build_start_time))
        track_result "Platform Builds" "fail" "Some platform builds failed (${build_duration}s)"
        
        # Check individual platform logs
        log_error "Build failure details:"
        if [[ -d "$PROJECT_DIR/dist/logs" ]]; then
            for log_file in "$PROJECT_DIR/dist/logs"/*.log; do
                if [[ -f "$log_file" ]] && grep -q "ERROR\|FAIL" "$log_file"; then
                    local platform=$(basename "$log_file" .log | sed 's/build-//')
                    log_error "  $platform build failed (see $(basename "$log_file"))"
                fi
            done
        fi
        return 1
    fi
}

# 6. Artifact validation
validate_artifacts() {
    if [[ "$SKIP_BUILDS" == true ]]; then
        log_section "6. Artifact Validation (SKIPPED)"
        track_result "Artifact Validation" "pass" "Skipped (no builds performed)"
        return 0
    fi
    
    log_section "6. Build Artifact Validation"
    
    local artifact_script="$SCRIPT_DIR/artifact-manager.sh"
    if [[ -f "$artifact_script" ]]; then
        log_check "Verifying build artifacts..."
        
        if "$artifact_script" verify > /dev/null 2>&1; then
            track_result "Artifact Integrity" "pass" "All artifacts verified successfully"
        else
            track_result "Artifact Integrity" "fail" "Some artifacts failed verification"
            return 1
        fi
        
        # Check artifact organization
        if "$artifact_script" organize --clean-first > /dev/null 2>&1; then
            track_result "Artifact Organization" "pass" "Artifacts organized successfully"
        else
            track_result "Artifact Organization" "warn" "Artifact organization had issues"
        fi
        
    else
        track_result "Artifact Management" "warn" "Artifact manager script not found"
    fi
    
    # Basic file system checks
    local dist_dir="$PROJECT_DIR/dist"
    if [[ -d "$dist_dir" ]]; then
        local artifact_count=$(find "$dist_dir" -name "*.apk" -o -name "*.aab" -o -name "*.tar.gz" -o -name "*.zip" -o -name "index.html" | wc -l | tr -d ' ')
        if [[ "$artifact_count" -gt 0 ]]; then
            track_result "Artifact Files" "pass" "$artifact_count build artifacts found"
        else
            track_result "Artifact Files" "fail" "No build artifacts found in dist/ directory"
        fi
    else
        track_result "Artifact Directory" "fail" "Build output directory not found"
    fi
}

# Generate final report
generate_report() {
    log_section "Pre-Checkin Validation Report"
    
    local success_rate=0
    if [[ "$TOTAL_CHECKS" -gt 0 ]]; then
        success_rate=$((PASSED_CHECKS * 100 / TOTAL_CHECKS))
    fi
    
    echo "Validation Summary:"
    echo "=================="
    echo "Total Checks: $TOTAL_CHECKS"
    echo "Passed: $PASSED_CHECKS"
    echo "Failed: $((TOTAL_CHECKS - PASSED_CHECKS))"
    echo "Success Rate: ${success_rate}%"
    echo
    
    # Show all results
    echo "Detailed Results:"
    echo "=================="
    for result in "${VALIDATION_RESULTS[@]}"; do
        echo "$result"
    done
    echo
    
    # Configuration summary
    echo "Configuration:"
    echo "=============="
    echo "Mode: $(if [[ "$QUICK_MODE" == true ]]; then echo "Quick"; else echo "Full"; fi)"
    echo "Platforms: $PLATFORMS"
    echo "Build Type: $BUILD_TYPE"
    echo "Parallel Builds: $PARALLEL_BUILDS"
    echo "Skip Builds: $SKIP_BUILDS"
    echo "Auto-fix: $FIX_ISSUES"
    echo "Log File: $PRE_CHECKIN_LOG"
    echo
    
    # Recommendations
    if [[ ${#FAILED_CHECKS[@]} -gt 0 ]]; then
        echo "Failed Checks:"
        echo "=============="
        for failed_check in "${FAILED_CHECKS[@]}"; do
            echo "✗ $failed_check"
        done
        echo
        
        echo "Recommendations:"
        echo "================"
        echo "1. Address the failed checks above"
        echo "2. Run individual scripts to debug specific issues:"
        echo "   - Environment: ./scripts/check-build-env.sh --fix"
        echo "   - Code Quality: flutter analyze"
        echo "   - Tests: flutter test"
        echo "   - Builds: ./scripts/build-all.sh --platforms=web"
        echo "3. Re-run this script after fixes: $0"
        echo
    else
        echo "🎉 All checks passed! Your code is ready for commit."
        echo
        echo "Next steps:"
        echo "==========="
        echo "1. git add . (if not already staged)"
        echo "2. git commit -m 'Your commit message'"
        echo "3. git push (when ready to share)"
        echo
    fi
    
    # Performance summary
    local total_time=$(($(date +%s) - START_TIME))
    echo "Validation completed in ${total_time} seconds."
}

# Main execution
main() {
    # Record start time
    START_TIME=$(date +%s)
    
    echo "🚀 Dark Room Game - Pre-Checkin Validation"
    echo "=========================================="
    echo
    
    # Parse arguments
    parse_args "$@"
    
    # Setup logging
    setup_logging
    
    # Show configuration
    log_info "Validation mode: $(if [[ "$QUICK_MODE" == true ]]; then echo "Quick"; else echo "Full"; fi)"
    log_info "Target platforms: $PLATFORMS"
    log_info "Build type: $BUILD_TYPE"
    if [[ "$SKIP_BUILDS" == true ]]; then
        log_info "Builds: SKIPPED"
    else
        log_info "Build mode: $(if [[ "$PARALLEL_BUILDS" == true ]]; then echo "Parallel"; else echo "Sequential"; fi)"
    fi
    echo
    
    # Change to project directory
    cd "$PROJECT_DIR"
    
    # Run validation steps
    local exit_code=0
    
    check_environment || exit_code=1
    check_git_status || exit_code=1
    check_code_quality || exit_code=1
    run_tests || exit_code=1
    verify_builds || exit_code=1
    validate_artifacts || exit_code=1
    
    # Generate final report
    generate_report
    
    # Exit with appropriate code
    if [[ $exit_code -eq 0 ]] && [[ ${#FAILED_CHECKS[@]} -eq 0 ]]; then
        log_success "🎉 Pre-checkin validation completed successfully!"
        exit 0
    else
        log_error "❌ Pre-checkin validation failed. Please address the issues above."
        exit 1
    fi
}

# Execute main function
main "$@"
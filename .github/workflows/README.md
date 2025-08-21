# GitHub Actions Workflows

This directory contains GitHub Actions workflows for automatically building and releasing the Dark Room game.

## Workflows

### 🔨 Build Workflow (`build.yml`)

**Triggers:**
- Push to `main` or `develop` branches
- Pull requests to `main` branch  
- Manual trigger via GitHub UI

**What it builds:**
- **Web**: Browser-playable version
- **Android**: APK and App Bundle (AAB)
- **iOS**: Unsigned iOS build
- **macOS**: Native macOS app
- **Windows**: Windows executable
- **Linux**: Linux binary

**Artifacts:** Build outputs are saved as downloadable artifacts for 30 days.

### 🚀 Release Workflow (`release.yml`)

**Triggers:**
- Pushing a version tag (e.g., `v1.0.0`, `v2.1.3`)

**What it does:**
1. Creates a GitHub release with the tag name
2. Builds the game for all platforms
3. Uploads platform-specific builds as release assets
4. Generates release notes template

## Usage

### Running Builds

Builds run automatically on every push to main/develop branches. To manually trigger a build:

1. Go to the **Actions** tab in your GitHub repository
2. Select **Build Dark Room Game** workflow
3. Click **Run workflow** button
4. Choose the branch and click **Run workflow**

### Creating Releases

To create a new release with downloadable builds:

1. **Tag your commit:**
   ```bash
   git tag v1.0.0
   git push origin v1.0.0
   ```

2. **The release workflow will automatically:**
   - Create a GitHub release
   - Build for all platforms
   - Upload build artifacts
   - Generate release notes

3. **Edit the release** (optional):
   - Add detailed changelog
   - Mark as pre-release if needed
   - Update description

### Download Builds

**From Build Workflow:**
- Go to Actions → Select a build run → Download artifacts

**From Release:**
- Go to Releases → Select version → Download assets

## Platform Notes

### Android
- **APK**: Direct install on Android devices
- **AAB**: For Google Play Store submission
- Requires enabling "Unknown Sources" for APK installation

### iOS
- Build is unsigned - requires proper signing for distribution
- Suitable for development/testing with proper provisioning profiles

### Desktop (Windows/macOS/Linux)
- Self-contained executables
- No additional installation required
- Extract archive and run

### Web
- Static files for web hosting
- Requires HTTPS for full functionality (audio, etc.)
- Can be deployed to GitHub Pages, Netlify, etc.

## Build Requirements

The workflows automatically install all required dependencies:
- Flutter SDK (3.24.3 stable)
- Platform-specific build tools
- Java 17 (for Android)
- System libraries (for Linux)

## Troubleshooting

### Build Failures
- Check the Actions tab for detailed error logs
- Most common issues: dependency conflicts, platform-specific errors
- Flutter version compatibility issues

### Release Issues  
- Ensure tag follows semantic versioning (`vX.Y.Z`)
- Check that all builds complete successfully
- Verify GitHub token permissions

## Security Notes

- iOS builds are unsigned (safe for development)
- All builds use official Flutter toolchain
- No secrets or API keys are embedded in builds
- All dependencies are pulled from official sources

## Customization

To modify the workflows:
1. Edit the YAML files in this directory
2. Test changes on a feature branch first
3. Monitor the Actions tab for results

For Flutter version updates, change the `flutter-version` in both workflow files.
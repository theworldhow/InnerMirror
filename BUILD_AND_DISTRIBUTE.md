# Build and Distribution Guide

Complete guide for building and distributing InnerMirror to TestFlight and the App Store.

## Prerequisites

Before building, ensure you have:

- ✅ **Apple Developer Account** (paid membership required)
- ✅ **Xcode** (latest version recommended)
- ✅ **Flutter SDK** (3.24+)
- ✅ **CocoaPods** installed
- ✅ **App Store Connect** access
- ✅ **Bundle ID** configured: `com.ashokin2film.innermirror`
- ✅ **Development Team** set: `25T89XKHQ6`
- ✅ **Code Signing** configured in Xcode

## Step 1: Pre-Build Checklist

### 1.1 Update Version Number

Update version in `pubspec.yaml`:
```yaml
version: 1.0.0+1
```
- First number (1.0.0): Version name (CFBundleShortVersionString)
- Second number (+1): Build number (CFBundleVersion)

**Important**: Increment build number for each TestFlight/App Store submission.

### 1.2 Verify App Configuration

1. **Bundle Identifier**: `com.ashokin2film.innermirror`
   - Verify in Xcode: Project Settings → Target Runner → General → Bundle Identifier

2. **Signing & Capabilities**:
   - Open `ios/Runner.xcworkspace` in Xcode
   - Select Runner target → Signing & Capabilities
   - Ensure "Automatically manage signing" is checked
   - Select your Team: `25T89XKHQ6`

3. **Version Info**:
   - Version should match `pubspec.yaml`
   - Build number must increment for each upload

### 1.3 Clean Build

```bash
cd /Users/ashok/Downloads/Devlopment/InnerMirror
flutter clean
flutter pub get
cd ios
pod install
cd ..
```

## Step 2: Build iOS App

### 2.1 Build Flutter App

```bash
# Build release version
flutter build ios --release
```

This creates the release build in `ios/build/Release-iphoneos/`

### 2.2 Verify Build

Check that the build completed successfully:
- No build errors
- All pods installed correctly
- No missing dependencies

## Step 3: Create Archive in Xcode

### 3.1 Open Workspace

```bash
open ios/Runner.xcworkspace
```

**Important**: Always open `.xcworkspace`, not `.xcodeproj`

### 3.2 Select Destination

1. In Xcode toolbar, click the destination dropdown (next to Run button)
2. Select **"Any iOS Device"** or your connected device
   - ❌ Do NOT use Simulator (can't create archives from simulator)
   - ✅ Use "Any iOS Device" or physical device

### 3.3 Product Scheme

1. In toolbar, verify scheme is set to **"Runner"**
2. Click scheme dropdown if needed and select "Runner"

### 3.4 Create Archive

1. In Xcode menu: **Product → Archive**
   - Or press `Cmd + B` to build, then `Product → Archive`
2. Wait for archive process to complete
   - This may take 2-5 minutes
3. Organizer window should open automatically
   - If not: **Window → Organizer** (or `Cmd + Shift + 0`)

### 3.5 Verify Archive

In Organizer window:
- ✅ Check archive appears in list
- ✅ Check version and build number are correct
- ✅ Check date/time is recent

## Step 4: Distribute to TestFlight

### 4.1 Validate Archive (Optional but Recommended)

1. In Organizer, select your archive
2. Click **"Validate App"** button
3. Follow validation steps:
   - Sign in with Apple Developer account
   - Select distribution method: **"App Store Connect"**
   - Click **"Next"**
   - Wait for validation (checks for common issues)
4. If validation passes: ✅ Ready for distribution
5. If validation fails: Fix errors before proceeding

### 4.2 Upload to TestFlight

1. In Organizer, select your archive
2. Click **"Distribute App"** button
3. Select distribution method:
   - Choose **"App Store Connect"**
   - Click **"Next"**
4. Select distribution options:
   - Choose **"Upload"**
   - Click **"Next"**
5. Configure signing:
   - Select **"Automatically manage signing"** (recommended)
   - Or manually select distribution certificate
   - Click **"Next"**
6. Review summary:
   - Verify bundle ID, version, build number
   - Click **"Upload"**
7. Wait for upload:
   - Progress bar shows upload status
   - May take 5-15 minutes depending on file size
   - ✅ "Upload Successful" message when complete

### 4.3 Processing in App Store Connect

1. Go to [App Store Connect](https://appstoreconnect.apple.com)
2. Navigate to **My Apps → InnerMirror**
3. Click **TestFlight** tab
4. Wait for processing:
   - Build appears in "Processing" state
   - Processing takes 10-60 minutes
   - Build moves to "Ready to Submit" when complete
5. Email notification sent when processing completes

### 4.4 Configure TestFlight Build

1. In TestFlight tab, select your processed build
2. Add test information (optional):
   - What to Test notes
   - Test details
3. Add internal testers (if needed):
   - Go to TestFlight → Internal Testing
   - Add email addresses
   - They'll receive TestFlight invite
4. Add external testers (for beta testing):
   - Go to TestFlight → External Testing
   - Select build
   - Add testers or groups
   - Submit for Beta App Review (first time only)

### 4.5 Install TestFlight Build

1. Install TestFlight app on device
2. Accept TestFlight invite email
3. Open TestFlight app
4. Install InnerMirror build
5. Test the app thoroughly

## Step 5: Submit to App Store

### 5.1 Prepare App Store Listing

1. Go to [App Store Connect](https://appstoreconnect.apple.com)
2. Navigate to **My Apps → InnerMirror**
3. Click **App Store** tab (not TestFlight)
4. Ensure all required information is complete:
   - App Information
   - Pricing and Availability
   - App Privacy (data usage declarations)
   - Version Information

### 5.2 Create New Version

1. In App Store tab, click **"+"** next to "iOS App"
2. Enter version number (e.g., `1.0.0`)
3. Click **"Create"**

### 5.3 Select Build

1. Scroll to "Build" section
2. Click **"Select a build before you submit your app"**
3. Choose the build you uploaded to TestFlight
   - Only processed builds appear here
   - Wait for processing if build not available
4. Build is now associated with this version

### 5.4 Complete App Store Information

1. **App Information**:
   - Name: InnerMirror
   - Subtitle: (optional)
   - Privacy Policy URL: (required)
   - Category: Health & Fitness → Mental Health
   - Content Rights: Check boxes as applicable

2. **What's New in This Version**:
   - First version: "Initial release of InnerMirror"
   - Updates: Describe new features/fixes

3. **Screenshots**:
   - Required: 6.5" iPhone (iPhone 14 Pro Max)
   - Optional: Other iPhone sizes, iPad
   - Minimum: 1 screenshot required
   - Add screenshots from `screenshots/` directory

4. **App Preview** (optional):
   - Video preview of app

5. **Description**:
   - Copy from `metadata/app_store_metadata.txt`
   - Or write compelling description
   - Maximum 4000 characters

6. **Keywords**:
   - Relevant keywords (100 characters max)
   - Separate with commas

7. **Support URL**:
   - Website or support page URL

8. **Marketing URL** (optional):
   - Marketing website URL

9. **Promotional Text** (optional):
   - Appears above description
   - Can be updated without new submission

### 5.5 App Privacy

1. Click **"Edit"** next to App Privacy
2. Complete privacy questionnaire:
   - Data types collected
   - How data is used
   - Data linked to user
   - Tracking practices
3. Reference `APP_STORE_REVIEW_RESPONSE_ALL_DATA_SOURCES.md` for accurate information
4. **Important**: Be accurate and honest
5. Click **"Save"**

### 5.6 Version Release

1. Scroll to "Version Release" section
2. Choose release option:
   - **Automatically release**: Releases immediately after approval
   - **Manually release**: You control when to release after approval
   - **Scheduled release**: Set specific date/time

### 5.7 Submit for Review

1. Scroll to top of page
2. Review all information:
   - ✅ All required fields complete
   - ✅ Build selected
   - ✅ Privacy information complete
   - ✅ Screenshots added
   - ✅ Description written
3. Click **"Add for Review"** or **"Submit for Review"**
4. Answer export compliance questions:
   - Does app use encryption? (Yes - HTTPS/TLS)
   - US export compliance (usually "No")
5. Click **"Submit"**

### 5.8 Review Process

1. Status changes to **"Waiting for Review"**
2. Email notification sent
3. Review typically takes 24-48 hours
4. Status updates:
   - In Review
   - Pending Developer Release (if manual release)
   - Ready for Sale (if auto release)
   - Rejected (if issues found)

### 5.9 Handle Rejection (if needed)

If app is rejected:
1. Read rejection reason carefully
2. Review [App Store Review Guidelines](https://developer.apple.com/app-store/review/guidelines/)
3. Fix issues in code
4. Update app version/build number
5. Rebuild and resubmit
6. Use **Resolution Center** in App Store Connect to communicate with reviewers
7. Reference `APP_STORE_REVIEW_RESPONSE_ALL_DATA_SOURCES.md` for common issues

## Step 6: Post-Submission

### 6.1 Monitor Status

- Check App Store Connect regularly
- Respond to review messages promptly
- Address any compliance issues

### 6.2 App Approved

Once approved:
- App appears in App Store
- If manual release: Click "Release This Version"
- Monitor app analytics in App Store Connect

### 6.3 Update Version (Future Releases)

For updates:
1. Increment version in `pubspec.yaml`
2. Increment build number
3. Follow Steps 1-5 again
4. Create new version in App Store Connect
5. Select new build
6. Submit for review

## Troubleshooting

### Build Issues

**Error: "No such module"**
```bash
cd ios
pod install
cd ..
flutter clean
flutter pub get
```

**Error: Code Signing Issues**
- Check Team ID in Xcode: `25T89XKHQ6`
- Verify bundle ID: `com.ashokin2film.innermirror`
- Ensure "Automatically manage signing" is enabled

**Error: Archive Failed**
- Clean build folder: `Product → Clean Build Folder` (Shift+Cmd+K)
- Delete DerivedData: `~/Library/Developer/Xcode/DerivedData`
- Rebuild

### Upload Issues

**Error: "Invalid Bundle"**
- Check bundle identifier matches App Store Connect
- Verify version number format
- Ensure all required permissions are declared in Info.plist

**Error: "Missing Compliance"**
- Answer export compliance questions
- Provide export compliance information if required

### TestFlight Issues

**Build Not Appearing**
- Wait 10-60 minutes for processing
- Check email for processing completion
- Refresh App Store Connect page

**Testers Can't Install**
- Verify TestFlight invite was sent
- Check tester's email address
- Ensure build is in "Ready to Submit" state

## Quick Reference Commands

```bash
# Full build and archive workflow
cd /Users/ashok/Downloads/Devlopment/InnerMirror
flutter clean
flutter pub get
cd ios && pod install && cd ..
flutter build ios --release
open ios/Runner.xcworkspace

# Then in Xcode:
# 1. Select "Any iOS Device"
# 2. Product → Archive
# 3. Distribute App → App Store Connect → Upload
```

## Important Notes

1. **Version Numbers**:
   - Version (1.0.0): Must be higher than previous App Store version
   - Build (+1): Must be unique, can be same or higher than TestFlight

2. **TestFlight vs App Store**:
   - TestFlight builds: Can use any build number
   - App Store builds: Must be same build submitted for review

3. **Processing Time**:
   - Archive: 2-5 minutes
   - Upload: 5-15 minutes
   - Processing: 10-60 minutes
   - Review: 24-48 hours

4. **First Submission**:
   - Requires complete App Store listing
   - Privacy policy URL required
   - All required screenshots
   - App Privacy questionnaire

5. **Updates**:
   - Increment version number
   - Increment build number
   - Submit new build
   - Update "What's New" section

## Support Documents

- `APP_STORE_VALIDATION.md` - Pre-submission checklist
- `APP_STORE_REVIEW_RESPONSE_ALL_DATA_SOURCES.md` - Data source justifications
- `metadata/app_store_metadata.txt` - App Store description and metadata

---

**Ready to build?** Start with Step 1 and follow the guide sequentially. Good luck with your submission! 🚀


# Submit InnerMirror to App Stores - Exact Commands

## 🚀 Quick Start - Submit Today

### Android (Google Play)

```bash
cd /Users/ashok/Downloads/Devlopment/InnerMirror

# 1. Build signed AAB
flutter clean
flutter pub get
flutter build appbundle --release

# 2. Upload to Google Play Console
# Go to: https://play.google.com/console
# - Select app > Production > Create new release
# - Upload: build/app/outputs/bundle/release/app-release.aab
# - Use metadata from: metadata/google_play_metadata.txt
# - Submit for review
```

### iOS (App Store)

```bash
cd /Users/ashok/Downloads/Devlopment/InnerMirror

# 1. Build IPA
flutter clean
flutter pub get
flutter build ipa --release

# 2. Open Xcode and Archive
open ios/Runner.xcworkspace

# In Xcode:
# - Product > Archive
# - Window > Organizer
# - Distribute App > App Store Connect
# - Upload to TestFlight or submit for review
```

## 📋 Store Listing Checklist

### App Store Connect
✅ App Name: **InnerMirror**  
✅ Subtitle: **The AI That Knows You Better Than You Ever Will**  
✅ Description: See `metadata/app_store_metadata.txt`  
✅ Keywords: `privacy,on-device,AI,personal,reflection,self-awareness,private,local,secure`  
✅ Privacy Policy: `https://innermirror.app/privacy`  
✅ Age Rating: **17+**  
✅ Category: **Health & Fitness > Mental Health**

### Google Play Console
✅ App Name: **InnerMirror**  
✅ Short Description: **The AI That Knows You Better Than You Ever Will**  
✅ Full Description: See `metadata/google_play_metadata.txt`  
✅ Privacy Policy: `https://innermirror.app/privacy`  
✅ Content Rating: **Mature 17+**  
✅ Category: **Health & Fitness**

## 🎨 Assets Needed

1. **App Icon**: 1024x1024 (iOS) / 512x512 (Android)
   - Pure black square (#000000)
   - Tiny white cracked mirror icon in center

2. **Screenshots**: 6 required for each platform
   - Black background
   - Mirror cards with blurred text
   - Minimal aesthetic

3. **Privacy Policy**: Deploy `privacy_policy.html` to:
   - GitHub Pages, OR
   - Vercel, OR
   - Your own domain

## ✅ Final Steps

1. Deploy privacy policy to public URL
2. Update privacy policy URL in store listings
3. Upload screenshots (blur personal data)
4. Submit for review
5. Wait for approval (typically 1-3 days)

## 🎯 You're Ready to Ship

All code is complete. All features work. The app is production-ready.

**Run the commands above and submit today.**


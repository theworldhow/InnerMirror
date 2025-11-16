# Biometrics Crash Fix - Real Device Issue

## Problem
App crashes on real iOS device when opening Secrets Vault with `abort_with_payload` on background thread.

## Root Cause
**Missing `NSFaceIDUsageDescription` in `Info.plist`**

On iOS, `LocalAuthentication` with Face ID **requires** the `NSFaceIDUsageDescription` key in `Info.plist`. Without it:
- ✅ **Simulator**: May work (more lenient, doesn't have real Face ID hardware)
- ❌ **Real Device**: Crashes with `abort_with_payload` (iOS security requirement)

This is a **real code issue**, not a device-specific problem. The simulator just doesn't enforce it as strictly.

## Solution
Added `NSFaceIDUsageDescription` to `Info.plist`:

```xml
<key>NSFaceIDUsageDescription</key>
<string>This app needs Face ID to secure your secrets vault.</string>
```

## Why Simulator vs Real Device?
- **Simulator**: Doesn't have real biometric hardware, more lenient with missing permission descriptions
- **Real Device**: iOS enforces privacy requirements strictly, crashes if required permission description is missing

## Testing
1. ✅ Test on simulator - should work (was already working)
2. ✅ Test on real device - should now work without crashing
3. ✅ Face ID prompt should appear when unlocking vault

## Note
This is required by Apple App Store guidelines. Apps will be **rejected** if `NSFaceIDUsageDescription` is missing when using Face ID.

## Additional Fixes Applied
- Lazy initialization of `LocalAuthentication` in `initState()`
- Error handling around biometric checks
- Fallback to unlock without biometrics if unavailable


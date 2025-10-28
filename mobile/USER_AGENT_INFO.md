# User-Agent Header Information

## Overview

All API requests from the Jinnie mobile app now include a comprehensive User-Agent header with device and app information.

## Format

```
Jinnie/[version] ([platform] [os_version]; [device_model]; [locale]) Build/[build_number]
```

## Examples

### iOS
```
Jinnie/1.0.3 (iOS 17.1; iPhone15,2; en_US) Build/4
```

### Android
```
Jinnie/1.0.3 (Android 14; Google Pixel 7; en_US) Build/4
```

## Information Included

| Field | Description | Example | Source |
|-------|-------------|---------|--------|
| **App Name** | Application name | `Jinnie` | Hardcoded |
| **App Version** | Semantic version | `1.0.3` | `pubspec.yaml` version |
| **Platform** | Operating system | `iOS` / `Android` | `Platform.isIOS` / `Platform.isAndroid` |
| **OS Version** | Operating system version | `17.1` / `14` | `DeviceInfoPlugin` |
| **Device Model** | Device identifier | `iPhone15,2` / `Google Pixel 7` | `DeviceInfoPlugin` |
| **Locale** | Language and region | `en_US` / `es_ES` | `Platform.localeName` |
| **Build Number** | App build number | `4` | `pubspec.yaml` build number |

## Why This Information Is Useful

### Backend Analytics
- **Platform Detection**: Accurately identify iOS vs Android users
- **Device Support**: Track which devices are using the app
- **OS Compatibility**: Monitor OS version distribution
- **Version Tracking**: See which app versions are in use

### Debugging
- **Error Context**: When errors occur, know exactly what device/OS/version
- **Platform-Specific Issues**: Identify iOS-only or Android-only bugs
- **Version Rollout**: Track adoption of new app versions

### Telegram Notifications
The platform emoji in Telegram logs (🍎 iOS / 🤖 Android / 🖥️ Web) is now based on this User-Agent header instead of defaulting to Web.

### User Support
When users report issues, the backend logs will show:
- What device they're using
- What OS version
- What app version
- Their locale (for localization issues)

## Implementation

### Location
- **Utility**: `/lib/utils/user_agent.dart`
- **Integration**: `/lib/services/api_service.dart` (Dio interceptor)

### How It Works
1. On first API request, `UserAgentBuilder.getUserAgent()` is called
2. Device and app info is collected once
3. User-Agent string is cached for performance
4. Header is added to all subsequent requests automatically

### Performance
- **First call**: ~50-100ms (device info collection)
- **Subsequent calls**: <1ms (cached)
- **Network impact**: ~100 bytes per request

## Privacy Considerations

All information included is:
- ✅ **Non-personal** (no user IDs, emails, etc.)
- ✅ **Standard HTTP practice** (browsers send similar info)
- ✅ **Device-level only** (no tracking across devices)
- ✅ **App-scoped** (only sent to Jinnie backend)

## Testing

To see the User-Agent in action:

1. Run app in debug mode
2. Make any API request
3. Check console for: `📱 User-Agent: Jinnie/1.0.3 (iOS 17.1; iPhone15,2; en_US) Build/4`
4. Check backend logs for platform detection: `🍎 iOS` or `🤖 Android`

## Maintenance

### Updating Version
Version is automatically pulled from `pubspec.yaml`:
```yaml
version: 1.0.3+4  # 1.0.3 = version, 4 = build number
```

### Cache Management
Cache is cleared automatically when:
- App restarts
- Can be manually cleared: `UserAgentBuilder.clearCache()`

## Troubleshooting

If User-Agent is not working:
1. Check console for `⚠️ Failed to set User-Agent` warnings
2. Verify packages are installed:
   - `package_info_plus: ^8.3.0`
   - `device_info_plus: ^11.3.3`
3. Falls back to `Jinnie/1.0.0` if error occurs

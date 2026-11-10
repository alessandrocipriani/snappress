# Native project setup

The `android/` and `ios/` folders are generated with `flutter create` and then adjusted as below. Keep these changes if you ever regenerate them.

## Android

**`android/app/src/main/AndroidManifest.xml`**, inside `<manifest>` (before `<application>`):

```xml
<!-- Release builds need it explicitly: debug builds get it automatically. -->
<uses-permission android:name="android.permission.INTERNET"/>
<uses-permission android:name="android.permission.USE_BIOMETRIC"/>
```

**`MainActivity.kt`** (`android/app/src/main/kotlin/io/github/alessandrocipriani/snappress/MainActivity.kt`): `local_auth` needs a `FlutterFragmentActivity`.

```kotlin
package io.github.alessandrocipriani.snappress

import io.flutter.embedding.android.FlutterFragmentActivity

class MainActivity : FlutterFragmentActivity()
```

**`android/app/build.gradle.kts`**: if the build complains about `minSdk`, set `minSdk = 23` in `defaultConfig`.

## iOS

**`ios/Runner/Info.plist`**, inside the main `<dict>`:

```xml
<key>NSFaceIDUsageDescription</key>
<string>SnapPress uses Face ID to unlock the app.</string>
<key>NSPhotoLibraryUsageDescription</key>
<string>SnapPress needs access to your photos to choose the image to publish.</string>
<key>NSCameraUsageDescription</key>
<string>SnapPress uses the camera to take the photo to publish.</string>
```

**Deployment target**: in Xcode, *Runner → General → Minimum Deployments*, use at least the version required by the plugins (Flutter prints it if it is too low).

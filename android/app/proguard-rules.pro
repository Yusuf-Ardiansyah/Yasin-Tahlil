# 1. Melindungi Flutter Internal
-keep class io.flutter.app.** { *; }
-keep class io.flutter.plugin.** { *; }
-keep class io.flutter.util.** { *; }
-keep class io.flutter.view.** { *; }
-keep class io.flutter.** { *; }
-keep class io.flutter.plugins.** { *; }

# 2. Melindungi Library Audio (Audioplayers)
-keep class com.ryanheise.audioservice.** { *; }
-keep class xyz.luan.audioplayers.** { *; }

# 3. Melindungi Library Adzan & Lokasi (Adhan, Geolocator)
-keep class com.batoulapps.adhan.** { *; }
-keep class com.baseflow.geolocator.** { *; }

# 4. Melindungi Notifikasi (Flutter Local Notifications)
-keep class com.dexterous.flutterlocalnotifications.** { *; }

# 5. Mencegah error pada pemrosesan JSON (jika ada)
-keepattributes Signature
-keepattributes *Annotation*
-keepattributes EnclosingMethod

# Tambahan untuk mengatasi error R8 Missing Class Play Core
-dontwarn com.google.android.play.core.**
-keep class com.google.android.play.core.** { *; }

# Mengabaikan missing classes lainnya yang menyebabkan build failed
-ignorewarnings
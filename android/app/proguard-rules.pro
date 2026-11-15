-keep class io.flutter.** { *; }
-keep class io.flutter.embedding.** { *; }

-keepattributes *Annotation*
-keepattributes Signature
-keepattributes InnerClasses
-keepattributes EnclosingMethod

-keepclassmembernames class kotlinx.** {
    volatile <fields>;
}

-dontwarn okhttp3.**
-dontwarn okio.**

-keep class com.baseflow.geolocator.** { *; }
-keep class io.flutter.plugins.imagepicker.** { *; }
-keep class com.dexterous.** { *; }

# Flutter Local Notifications & Gson R8/ProGuard Rules
-keepattributes Signature
-keepattributes *Annotation*
-keepattributes EnclosingMethod
-keepattributes InnerClasses

# Keep Gson classes and generic type tokens
-keep class com.google.gson.** { *; }
-keep class com.google.gson.reflect.TypeToken { *; }
-keep class * extends com.google.gson.reflect.TypeToken
-keep class * extends com.google.gson.TypeAdapter
-keepclassmembers class * {
    @com.google.gson.annotations.SerializedName <fields>;
}

# Keep Flutter Local Notifications plugin and all models/receivers
-keep class com.dexterous.** { *; }
-keep class com.dexterous.flutterlocalnotifications.** { *; }
-keepclassmembers class com.dexterous.flutterlocalnotifications.** { *; }
-dontwarn com.dexterous.flutterlocalnotifications.**

# Keep Lifecycle observer for Flutter plugins
-keep class androidx.lifecycle.DefaultLifecycleObserver

# Retain R class and drawable identifiers for dynamic runtime lookups
-keepclassmembers class **.R$drawable {
    public static final int ic_notification;
}
-keepclassmembers class **.R$* {
    public static <fields>;
}
-keep class **.R$* {
    *;
}

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

# WorkManager
-keep class androidx.work.** { *; }
-dontwarn androidx.work.**

# Flutter Community WorkManager plugin
-keep class dev.fluttercommunity.workmanager.** { *; }
-dontwarn dev.fluttercommunity.workmanager.**

# Kals Native Storage plugin
-keep class com.kals.kals_money_manager.kals_storage.** { *; }
-dontwarn com.kals.kals_money_manager.kals_storage.**

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

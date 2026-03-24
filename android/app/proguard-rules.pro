# Flutter wrapper — keep the embedding entry point
-keep class io.flutter.app.** { *; }
-keep class io.flutter.plugin.** { *; }
-keep class io.flutter.util.** { *; }
-keep class io.flutter.view.** { *; }
-keep class io.flutter.** { *; }
-keep class io.flutter.plugins.** { *; }

# flutter_secure_storage — DPAPI / EncryptedSharedPreferences internals
-keep class com.it_nomads.fluttersecurestorage.** { *; }

# flutter_local_notifications
-keep class com.dexterous.** { *; }

# SQLite native libs
-keep class org.sqlite.** { *; }
-keep class io.requery.android.database.** { *; }

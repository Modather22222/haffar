# Flutter / R8 defaults
-keep class io.flutter.** { *; }
-dontwarn io.flutter.embedding.**

# Supabase / PostgREST JSON
-keep class io.supabase.** { *; }
-keep class org.json.** { *; }

# Keep line numbers for readable crash reports (mapping uploaded by CI)
-keepattributes SourceFile,LineNumberTable
-renamesourcefileattribute SourceFile

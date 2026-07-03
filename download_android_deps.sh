#!/bin/bash
LOCAL_REPO="/Users/zouyuming/WorkBuddy/2026-06-27-13-26-33/course_manager/local-maven-repo"
FLUTTER_REPO="https://storage.googleapis.com/download.flutter.io"
MAVEN_CENTRAL="https://repo1.maven.org/maven2"
GOOGLE_MAVEN="https://dl.google.com/dl/android/maven2"

# Function to download an artifact from multiple sources
download_artifact() {
    local group_path="$1"  # e.g., androidx/lifecycle/lifecycle-common
    local version="$2"     # e.g., 2.7.0
    local artifact_name="$3"  # e.g., lifecycle-common
    local ext="${4:-aar}"  # default to aar for AndroidX, jar for Java
    
    local dir="$LOCAL_REPO/$group_path/$version"
    mkdir -p "$dir"
    
    # Try Flutter repo first (for AndroidX), then Google Maven, then Maven Central
    local base_name="${artifact_name}-${version}"
    
    # Download POM
    if [ ! -f "$dir/${base_name}.pom" ]; then
        for repo in "$FLUTTER_REPO" "$GOOGLE_MAVEN" "$MAVEN_CENTRAL"; do
            echo "Trying POM: ${repo}/${group_path}/${version}/${base_name}.pom"
            if curl -sL -f -o "$dir/${base_name}.pom" "${repo}/${group_path}/${version}/${base_name}.pom"; then
                echo "  ✓ POM downloaded from ${repo}"
                break
            fi
        done
    fi
    
    # Download main artifact (aar or jar)
    if [ ! -f "$dir/${base_name}.${ext}" ]; then
        for repo in "$FLUTTER_REPO" "$GOOGLE_MAVEN" "$MAVEN_CENTRAL"; do
            echo "Trying ${ext}: ${repo}/${group_path}/${version}/${base_name}.${ext}"
            if curl -sL -f -o "$dir/${base_name}.${ext}" "${repo}/${group_path}/${version}/${base_name}.${ext}"; then
                echo "  ✓ ${ext} downloaded from ${repo}"
                break
            fi
        done
    fi
    
    # Also try .jar for AndroidX (some have both aar and jar)
    if [ "$ext" = "aar" ] && [ ! -f "$dir/${base_name}.jar" ]; then
        for repo in "$GOOGLE_MAVEN" "$FLUTTER_REPO" "$MAVEN_CENTRAL"; do
            if curl -sL -f -o "$dir/${base_name}.jar" "${repo}/${group_path}/${version}/${base_name}.jar"; then
                echo "  ✓ JAR also available"
                break
            fi
        done
    fi
}

# Flutter embedding
download_artifact "io/flutter/flutter_embedding_debug" "1.0.0-cf56914b326edb0ccb123ffdc60f00060bd513fa" "flutter_embedding_debug" "jar"

# AndroidX dependencies needed by flutter_embedding and plugins
download_artifact "androidx/annotation/annotation" "1.9.1" "annotation" "aar"
download_artifact "androidx/annotation/annotation" "1.7.0" "annotation" "aar"
download_artifact "androidx/core/core" "1.13.1" "core" "aar"
download_artifact "androidx/core/core" "1.3.0" "core" "aar"
download_artifact "androidx/core/core-ktx" "1.10.1" "core-ktx" "aar"
download_artifact "androidx/lifecycle/lifecycle-common" "2.7.0" "lifecycle-common" "jar"
download_artifact "androidx/lifecycle/lifecycle-common-java8" "2.7.0" "lifecycle-common-java8" "aar"
download_artifact "androidx/lifecycle/lifecycle-process" "2.7.0" "lifecycle-process" "aar"
download_artifact "androidx/lifecycle/lifecycle-runtime" "2.7.0" "lifecycle-runtime" "aar"
download_artifact "androidx/fragment/fragment" "1.7.1" "fragment" "aar"
download_artifact "androidx/tracing/tracing" "1.2.0" "tracing" "aar"
download_artifact "androidx/window/window-java" "1.2.0" "window-java" "aar"
download_artifact "androidx/media/media" "1.1.0" "media" "aar"

# Other dependencies
download_artifact "com/getkeepsafe/relinker/relinker" "1.4.5" "relinker" "jar"

echo "Download complete!"

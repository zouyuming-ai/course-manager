#!/usr/bin/env python3
"""Download all transitive ML Kit dependencies to local-maven-repo."""
import xml.etree.ElementTree as ET
import os
import subprocess
import sys

REPO_BASE = "/Users/zouyuming/WorkBuddy/2026-06-27-13-26-33/course_manager/local-maven-repo"
GOOGLE_MAVEN = "https://dl.google.com/dl/android/maven2"
MAVEN_CENTRAL = "https://repo.maven.apache.org/maven2"

def parse_pom_deps(pom_path):
    """Parse POM file and extract all dependencies."""
    deps = []
    try:
        tree = ET.parse(pom_path)
        root = tree.getroot()
        ns = {'m': 'http://maven.apache.org/POM/4.0.0'}
        for dep in root.findall('.//m:dependency', ns):
            g = dep.find('m:groupId', ns)
            a = dep.find('m:artifactId', ns)
            v = dep.find('m:version', ns)
            if g is not None and a is not None and v is not None:
                deps.append((g.text, a.text, v.text))
    except Exception as e:
        print(f"Warning: could not parse {pom_path}: {e}")
    return deps

def download(group, artifact, version, repo_url):
    """Download AAR/JAR + POM for a dependency."""
    group_path = group.replace('.', '/')
    dir_path = os.path.join(REPO_BASE, group_path, artifact, version)
    os.makedirs(dir_path, exist_ok=True)
    
    # Try AAR first (for Android libraries), then JAR
    base_name = f"{artifact}-{version}"
    downloaded = False
    
    # Try AAR
    aar_url = f"{repo_url}/{group_path}/{artifact}/{version}/{base_name}.aar"
    aar_path = os.path.join(dir_path, f"{base_name}.aar")
    if not os.path.exists(aar_path):
        result = subprocess.run(
            ['curl', '--noproxy', '*', '-L', '-o', aar_path, aar_url],
            capture_output=True, timeout=30
        )
        if result.returncode == 0 and os.path.exists(aar_path) and os.path.getsize(aar_path) > 100:
            downloaded = True
            print(f"  ✅ AAR: {group}:{artifact}:{version}")
    
    # Try JAR if AAR didn't work
    jar_url = f"{repo_url}/{group_path}/{artifact}/{version}/{base_name}.jar"
    jar_path = os.path.join(dir_path, f"{base_name}.jar")
    if not downloaded and not os.path.exists(jar_path):
        result = subprocess.run(
            ['curl', '--noproxy', '*', '-L', '-o', jar_path, jar_url],
            capture_output=True, timeout=30
        )
        if result.returncode == 0 and os.path.exists(jar_path) and os.path.getsize(jar_path) > 100:
            downloaded = True
            print(f"  ✅ JAR: {group}:{artifact}:{version}")
    
    # Always download POM
    pom_url = f"{repo_url}/{group_path}/{artifact}/{version}/{base_name}.pom"
    pom_path = os.path.join(dir_path, f"{base_name}.pom")
    if not os.path.exists(pom_path):
        result = subprocess.run(
            ['curl', '--noproxy', '*', '-L', '-o', pom_path, pom_url],
            capture_output=True, timeout=30
        )
        if result.returncode == 0 and os.path.exists(pom_path) and os.path.getsize(pom_path) > 100:
            print(f"  ✅ POM: {group}:{artifact}:{version}")
            return pom_path
    
    return None

def is_already_local(group, artifact, version):
    """Check if dependency already exists in local-maven-repo."""
    group_path = group.replace('.', '/')
    dir_path = os.path.join(REPO_BASE, group_path, artifact, version)
    base_name = f"{artifact}-{version}"
    # Check if AAR or JAR exists
    if os.path.exists(os.path.join(dir_path, f"{base_name}.aar")) or \
       os.path.exists(os.path.join(dir_path, f"{base_name}.jar")):
        return True
    return False

# Known deps to download (from ML Kit plugins)
initial_deps = [
    ("com.google.mlkit", "text-recognition", "16.0.0"),
    ("com.google.mlkit", "text-recognition-chinese", "16.0.0"),
    ("com.google.mlkit", "text-recognition-devanagari", "16.0.0"),
    ("com.google.mlkit", "text-recognition-japanese", "16.0.0"),
    ("com.google.mlkit", "text-recognition-korean", "16.0.0"),
    ("com.google.mlkit", "vision-common", "17.3.0"),
]

# BFS to download all transitive deps
queue = list(initial_deps)
visited = set()
all_poms = []

while queue:
    group, artifact, version = queue.pop(0)
    key = f"{group}:{artifact}:{version}"
    if key in visited:
        continue
    visited.add(key)
    
    # Skip AndroidX deps (usually already cached or can be downloaded by Gradle)
    # Skip Kotlin deps (already in local-maven-repo)
    # Focus on Google/ML Kit specific deps
    
    if is_already_local(group, artifact, version):
        print(f"  ⏭️  Already local: {key}")
        # Still parse POM for transitive deps
        group_path = group.replace('.', '/')
        pom_path = os.path.join(REPO_BASE, group_path, artifact, version, f"{artifact}-{version}.pom")
        if os.path.exists(pom_path):
            deps = parse_pom_deps(pom_path)
            for g, a, v in deps:
                queue.append((g, a, v))
        continue
    
    # Determine repo URL
    if 'google' in group or 'mlkit' in group or 'android' in group.replace('androidx', ''):
        repo_url = GOOGLE_MAVEN
    else:
        repo_url = MAVEN_CENTRAL
    
    pom_path = download(group, artifact, version, repo_url)
    if pom_path:
        deps = parse_pom_deps(pom_path)
        for g, a, v in deps:
            queue.append((g, a, v))
    else:
        # Try Maven Central as fallback
        if repo_url != MAVEN_CENTRAL:
            pom_path = download(group, artifact, version, MAVEN_CENTRAL)
            if pom_path:
                deps = parse_pom_deps(pom_path)
                for g, a, v in deps:
                    queue.append((g, a, v))

print(f"\nDone! Downloaded {len(visited)} dependencies.")

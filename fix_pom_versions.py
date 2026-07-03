#!/usr/bin/env python3
"""Fix POMs that have dependency entries missing version numbers.

After stripping parent POMs, some dependencies lost their version numbers
which were inherited from parent's <dependencyManagement> section.

This script:
1. Finds all POMs with <dependency> entries that have no <version>
2. For known artifacts, hard-codes the correct version
3. Removes test-scoped dependencies (they're not needed for build classpath)
"""

import os
import re
import xml.etree.ElementTree as ET

REPO_DIR = "/Users/zouyuming/WorkBuddy/2026-06-27-13-26-33/course_manager/local-maven-repo"

# Known versions for dependencies that lost their version from parent POMs
# These are the versions used by AGP 8.7.3's transitive dependency chain
KNOWN_VERSIONS = {
    # jaxb-runtime:2.3.2 dependencies
    ("jakarta.xml.bind", "jakarta.xml.bind-api"): "2.3.2",
    ("org.glassfish.jaxb", "txw2"): "2.3.2",
    ("com.sun.istack", "istack-commons-runtime"): "3.0.8",
    ("org.jvnet.staxex", "stax-ex"): "1.8.1",
    ("com.sun.xml.fastinfoset", "FastInfoset"): "1.2.16",
    ("jakarta.activation", "jakarta.activation-api"): "1.2.1",
    
    # jimfs:1.1 dependencies  
    ("junit", "junit"): "4.13.2",
    ("com.google.guava", "guava-testlib"): "32.0.1-jre",
    ("com.google.truth", "truth"): "1.1.3",
    
    # httpclient dependencies
    ("commons-logging", "commons-logging"): "1.2",
    
    # guava dependencies
    ("com.google.guava", "failureaccess"): "1.0.1",
    ("com.google.guava", "listenablefuture"): "9999.0-empty-to-avoid-conflict-with-guava",
    ("com.google.j2objc", "j2objc-annotations"): "1.3",
    
    # netty dependencies
    ("io.netty", "netty-codec-http"): "4.1.93.Final",
    ("io.netty", "netty-codec-socks"): "4.1.93.Final",
    
    # netty test dependencies (will be removed)
    ("org.mockito", "mockito-core"): "4.11.0",
    ("org.reflections", "reflections"): "0.10.2",
}

def find_all_poms():
    poms = []
    for root, dirs, files in os.walk(REPO_DIR):
        for f in files:
            if f.endswith('.pom'):
                poms.append(os.path.join(root, f))
    return poms

def fix_dependency_versions(pom_path):
    """Fix POM dependencies that are missing version numbers."""
    with open(pom_path, 'r', encoding='utf-8') as f:
        content = f.read()
    
    if '<project' not in content:
        return False
    
    modified = False
    
    # Parse XML
    try:
        content_no_ns = re.sub(r'\sxmlns[^>]*', '', content)
        content_no_ns = re.sub(r'<(/?\w+):', r'<\1', content_no_ns)
        root = ET.fromstring(content_no_ns)
    except ET.ParseError as e:
        print(f"  XML PARSE ERROR in {pom_path}: {e}")
        return False
    
    # Find dependencies section
    deps_elem = root.find('dependencies')
    if deps_elem is None:
        return False
    
    deps_to_remove = []
    
    for dep in deps_elem.findall('dependency'):
        gid_elem = dep.find('groupId')
        aid_elem = dep.find('artifactId')
        ver_elem = dep.find('version')
        scope_elem = dep.find('scope')
        
        if gid_elem is None or aid_elem is None:
            continue
        
        gid = gid_elem.text
        aid = aid_elem.text
        
        # Remove test-scoped dependencies entirely (not needed for build)
        if scope_elem is not None and scope_elem.text == 'test':
            deps_to_remove.append(dep)
            modified = True
            continue
        
        # If version is missing, look up in KNOWN_VERSIONS
        if ver_elem is None or (ver_elem.text is not None and ver_elem.text.startswith('${')):
            key = (gid, aid)
            if key in KNOWN_VERSIONS:
                version = KNOWN_VERSIONS[key]
                if ver_elem is None:
                    ver = ET.SubElement(dep, 'version')
                    ver.text = version
                else:
                    ver_elem.text = version
                modified = True
                print(f"  Set version {version} for {gid}:{aid} in {os.path.basename(pom_path)}")
            elif ver_elem is None:
                print(f"  WARNING: No known version for {gid}:{aid} in {os.path.basename(pom_path)}")
    
    # Remove test dependencies
    for dep in deps_to_remove:
        deps_elem.remove(dep)
        gid = dep.find('groupId').text if dep.find('groupId') is not None else '?'
        aid = dep.find('artifactId').text if dep.find('artifactId') is not None else '?'
        print(f"  Removed test dependency {gid}:{aid} from {os.path.basename(pom_path)}")
    
    if not modified:
        return False
    
    # Write back - need to handle namespace
    # ET.tostring adds ns0 namespace prefix which Maven doesn't like
    xml_str = ET.tostring(root, encoding='unicode')
    # Remove any namespace prefixes that ET might have added
    xml_str = re.sub(r'<ns0:', '<', xml_str)
    xml_str = re.sub(r'</ns0:', '</', xml_str)
    xml_str = re.sub(r'\sxmlns:ns0="[^"]*"', '', xml_str)
    
    # Add XML declaration if missing
    if not xml_str.startswith('<?xml'):
        xml_str = '<?xml version="1.0" encoding="UTF-8"?>\n' + xml_str
    
    # Pretty print - add newlines after closing tags
    xml_str = re.sub(r'>\s*<', '>\n<', xml_str)
    
    with open(pom_path, 'w', encoding='utf-8') as f:
        f.write(xml_str)
    
    return True

def main():
    poms = find_all_poms()
    print(f"Found {len(poms)} POM files")
    
    fixed_count = 0
    for pom in sorted(poms):
        if fix_dependency_versions(pom):
            fixed_count += 1
    
    print(f"\nFixed {fixed_count} POM files")

if __name__ == '__main__':
    main()

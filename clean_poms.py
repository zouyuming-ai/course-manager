#!/usr/bin/env python3
"""Clean up POM files that have been mangled by previous fix scripts.

Issues to fix:
1. Duplicate <artifactId> and <version> at project level (added by fix scripts)
2. xmlns:xsi namespace prefix causing XML parse errors
3. Missing <groupId> at project level (some still missing after partial fixes)
4. Elements in wrong order (groupId should come before artifactId)

Strategy: For each POM, parse it carefully, remove duplicates, ensure correct order.
"""

import os
import re

REPO_DIR = "/Users/zouyuming/WorkBuddy/2026-06-27-13-26-33/course_manager/local-maven-repo"

def find_all_poms():
    poms = []
    for root, dirs, files in os.walk(REPO_DIR):
        for f in files:
            if f.endswith('.pom'):
                poms.append(os.path.join(root, f))
    return poms

def infer_gav_from_path(pom_path):
    """Infer groupId, artifactId, version from Maven directory structure."""
    rel_path = os.path.relpath(pom_path, REPO_DIR)
    parts = rel_path.split(os.sep)
    if len(parts) >= 4:
        pom_filename = parts[-1]
        version = parts[-2]
        artifact_id = parts[-3]
        groupid_parts = parts[:-3]
        group_id = '.'.join(groupid_parts)
        return group_id, artifact_id, version
    return None, None, None

def clean_pom(pom_path):
    """Clean up a POM file, removing duplicates and fixing element order."""
    with open(pom_path, 'r', encoding='utf-8') as f:
        content = f.read()
    
    if '<project' not in content and '<?xml' not in content:
        # Not a valid POM - skip
        return False
    
    group_id, artifact_id, version = infer_gav_from_path(pom_path)
    if group_id is None:
        return False
    
    # Step 1: Find the <project> opening tag and everything after it
    project_match = re.search(r'<project[^>]*>', content)
    if not project_match:
        return False
    
    project_tag = project_match.group(0)
    after_project = content[project_match.end():]
    
    # Handle the case where project tag spans multiple lines
    # Find the complete project opening tag
    project_open_end = project_match.end()
    
    # Step 2: Find the </project> closing tag
    project_close_match = re.search(r'</project>', content)
    if not project_close_match:
        return False
    
    # Extract everything between <project> and </project>
    inner_content = content[project_open_end:project_close_match.start()]
    
    # Step 3: Remove all existing project-level GAV elements (groupId, artifactId, version)
    # These are elements that appear at the project level, not inside <dependencies> etc.
    # We need to be careful to only remove top-level ones
    
    # Strategy: rebuild the inner content section by section
    # Sections: modelVersion, groupId, artifactId, version, then everything else
    
    # Extract modelVersion if present
    model_version_match = re.search(r'<modelVersion>.*?</modelVersion>', inner_content, re.DOTALL)
    model_version = model_version_match.group(0) if model_version_match else '<modelVersion>4.0.0</modelVersion>'
    
    # Find the <dependencies> section (or first non-GAV element after GAV block)
    # We want to keep everything that's NOT a duplicate GAV element at the project level
    
    # Remove ALL standalone <groupId>, <artifactId>, <version> lines from the top section
    # (before <dependencies> or <name> or <packaging> etc.)
    
    # Actually, let's be more surgical: find where the "header" section ends
    # The header is: modelVersion, groupId, artifactId, version
    # After that comes: name, description, url, licenses, developers, properties, dependencies, etc.
    
    # Find the first "content" element (name, packaging, description, url, properties, licenses, etc.)
    content_start_match = re.search(
        r'<(?:name|packaging|description|url|properties|licenses|developers|scm|dependencies|dependencyManagement|build|profiles|repositories|reporting|distributionManagement)',
        inner_content
    )
    
    if content_start_match:
        header_section = inner_content[:content_start_match.start()]
        content_section = inner_content[content_start_match.start():]
    else:
        # No content elements found - entire inner is header
        header_section = inner_content
        content_section = ''
    
    # Clean the header section - remove all GAV elements
    # Keep only modelVersion
    header_cleaned = model_version + '\n'
    
    # Add correct GAV
    header_cleaned += f'  <groupId>{group_id}</groupId>\n'
    header_cleaned += f'  <artifactId>{artifact_id}</artifactId>\n'
    header_cleaned += f'  <version>{version}</version>\n'
    
    # Rebuild the POM
    new_content = content[:project_open_end] + '\n' + header_cleaned + content_section + '</project>\n'
    
    # Step 4: Clean up XML namespace issues
    # Ensure xsi namespace is properly declared
    if 'xmlns:xsi' not in project_tag and 'xsi:schemaLocation' in content:
        # Add xmlns:xsi to project tag
        project_tag = project_tag.replace('>', ' xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance">')
        new_content = project_tag + '\n' + header_cleaned + content_section + '</project>\n'
    
    # Check if content changed
    with open(pom_path, 'r', encoding='utf-8') as f:
        old_content = f.read()
    
    if new_content == old_content:
        return False
    
    with open(pom_path, 'w', encoding='utf-8') as f:
        f.write(new_content)
    
    print(f"  CLEANED: {os.path.relpath(pom_path, REPO_DIR)}")
    return True

def main():
    poms = find_all_poms()
    print(f"Found {len(poms)} POM files")
    
    fixed_count = 0
    for pom in sorted(poms):
        if clean_pom(pom):
            fixed_count += 1
    
    print(f"\nCleaned {fixed_count} POM files")

if __name__ == '__main__':
    main()

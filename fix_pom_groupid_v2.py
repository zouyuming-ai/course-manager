#!/usr/bin/env python3
"""Fix POMs in local-maven-repo that are missing top-level <groupId>.

The previous parent-stripping script removed <parent> blocks, which sometimes
contained the <groupId> that the project-level <groupId> was inheriting from.
This script detects POMs where the <project> element has no direct <groupId>
child (not counting groupId inside <dependency> or <parent> sub-elements),
and adds the correct groupId inferred from the Maven directory structure.

Directory structure convention:
  local-maven-repo/{groupId-path}/{artifactId}/{version}/{artifactId}-{version}.pom
  where groupId-path uses '/' as separator (e.g., com/google/code/gson)
  and groupId uses '.' as separator (e.g., com.google.code.gson)
"""

import os
import re
import xml.etree.ElementTree as ET

REPO_DIR = "/Users/zouyuming/WorkBuddy/2026-06-27-13-26-33/course_manager/local-maven-repo"

def find_all_poms():
    """Walk the repo and find all .pom files."""
    poms = []
    for root, dirs, files in os.walk(REPO_DIR):
        for f in files:
            if f.endswith('.pom'):
                poms.append(os.path.join(root, f))
    return poms

def infer_groupid_from_path(pom_path):
    """Infer groupId from the Maven directory structure path.
    
    Path format: REPO_DIR/{groupId-dots-as-slashes}/{artifactId}/{version}/{pom}
    We need to extract the groupId-dots-as-slashes portion.
    """
    rel_path = os.path.relpath(pom_path, REPO_DIR)
    parts = rel_path.split(os.sep)
    # parts = [g1, g2, ..., gN, artifactId, version, pomfile]
    # The version directory is always the second-to-last directory
    # The artifactId directory is always the third-to-last directory
    # Everything before that is the groupId path
    if len(parts) >= 4:
        # e.g., ['com', 'google', 'code', 'gson', 'gson', '2.10.1', 'gson-2.10.1.pom']
        # We need to find where artifactId starts
        # The pom file name is like {artifactId}-{version}.pom
        pom_filename = parts[-1]
        version = parts[-2]
        artifact_id = parts[-3]
        # Everything from index 0 to -3 is the groupId path
        groupid_parts = parts[:-3]
        groupid = '.'.join(groupid_parts)
        return groupid, artifact_id, version
    return None, None, None

def has_project_level_groupid(pom_content):
    """Check if the POM has a <groupId> directly under <project>, 
    not inside <dependency>, <parent>, or other sub-elements.
    
    We look for a pattern like:
      <project ...>
        <groupId>...</groupId>
    where <groupId> appears as a direct child of <project>, before
    any <dependencies> or <parent> block.
    """
    # Parse as XML to properly detect structure
    try:
        # Remove XML namespace for simpler parsing
        content_no_ns = re.sub(r'\sxmlns[^>]*', '', pom_content)
        # Remove namespace prefixes
        content_no_ns = re.sub(r'<(/?\w+):', r'<\1', content_no_ns)
        root = ET.fromstring(content_no_ns)
    except ET.ParseError:
        # Try a regex-based approach as fallback
        # Look for <groupId> that appears right after <project> opening tag
        # and before any <dependencies>, <parent>, <dependencyManagement> etc.
        pattern = r'<project[^>]*>\s*<groupId>'
        if re.search(pattern, pom_content):
            return True
        # Also check for <groupId> between <project> and <modelVersion> or other
        # top-level elements (but NOT inside <dependencies> block)
        # Find everything between <project> opening and <dependencies> opening
        project_match = re.search(r'<project[^>]*>(.*?)(?:<dependencies|<parent|</project)', pom_content, re.DOTALL)
        if project_match:
            header = project_match.group(1)
            if '<groupId>' in header:
                return True
        return False
    
    # Check if <project> has a direct child <groupId>
    for child in root:
        if child.tag == 'groupId' or child.tag.endswith('}groupId'):
            return True
        # Stop checking after we hit dependencies/parent - groupId should be before these
        if child.tag in ('dependencies', 'parent', 'dependencyManagement', 
                         'profiles', 'repositories', 'pluginRepositories',
                         'reporting', 'distributionManagement'):
            break
    return False

def has_project_level_artifactid(pom_content):
    """Check if POM has <artifactId> directly under <project>."""
    try:
        content_no_ns = re.sub(r'\sxmlns[^>]*', '', pom_content)
        content_no_ns = re.sub(r'<(/?\w+):', r'<\1', content_no_ns)
        root = ET.fromstring(content_no_ns)
    except ET.ParseError:
        pattern = r'<project[^>]*>\s*<artifactId>'
        return bool(re.search(pattern, pom_content))
    
    for child in root:
        if child.tag == 'artifactId' or child.tag.endswith('}artifactId'):
            return True
        if child.tag in ('dependencies', 'parent', 'dependencyManagement'):
            break
    return False

def has_project_level_version(pom_content):
    """Check if POM has <version> directly under <project>."""
    try:
        content_no_ns = re.sub(r'\sxmlns[^>]*', '', pom_content)
        content_no_ns = re.sub(r'<(/?\w+):', r'<\1', content_no_ns)
        root = ET.fromstring(content_no_ns)
    except ET.ParseError:
        pattern = r'<project[^>]*>\s*<version>'
        return bool(re.search(pattern, pom_content))
    
    for child in root:
        if child.tag == 'version' or child.tag.endswith('}version'):
            return True
        if child.tag in ('dependencies', 'parent', 'dependencyManagement'):
            break
    return False

def fix_pom(pom_path):
    """Fix a POM file that is missing top-level groupId/artifactId/version."""
    with open(pom_path, 'r', encoding='utf-8') as f:
        content = f.read()
    
    inferred_gid, inferred_aid, inferred_ver = infer_groupid_from_path(pom_path)
    if inferred_gid is None:
        print(f"  WARNING: Cannot infer groupId from path: {pom_path}")
        return False
    
    needs_fix = False
    missing_items = []
    
    if not has_project_level_groupid(content):
        missing_items.append(('groupId', inferred_gid))
        needs_fix = True
    
    if not has_project_level_artifactid(content):
        missing_items.append(('artifactId', inferred_aid))
        needs_fix = True
    
    if not has_project_level_version(content):
        missing_items.append(('version', inferred_ver))
        needs_fix = True
    
    if not needs_fix:
        return False
    
    # Find where to insert - right after <project> opening tag
    # We want to insert after <modelVersion> if it exists, or right after <project>
    project_open_match = re.search(r'<project[^>]*>', content)
    if not project_open_match:
        print(f"  WARNING: No <project> tag found in: {pom_path}")
        return False
    
    # Check if <modelVersion> exists right after <project>
    after_project = content[project_open_match.end():]
    model_version_match = re.match(r'\s*<modelVersion>.*?</modelVersion>', after_project)
    
    if model_version_match:
        # Insert after modelVersion
        insert_pos = project_open_match.end() + model_version_match.end()
    else:
        # Insert right after <project> tag
        insert_pos = project_open_match.end()
    
    # Build the XML elements to insert
    insert_xml = '\n'
    for tag, value in missing_items:
        insert_xml += f'  <{tag}>{value}</{tag}>\n'
    
    # Insert into content
    new_content = content[:insert_pos] + insert_xml + content[insert_pos:]
    
    with open(pom_path, 'w', encoding='utf-8') as f:
        f.write(new_content)
    
    print(f"  FIXED: {pom_path}")
    for tag, value in missing_items:
        print(f"    Added <{tag}>{value}</{tag}>")
    return True

def main():
    poms = find_all_poms()
    print(f"Found {len(poms)} POM files in local-maven-repo")
    
    fixed_count = 0
    for pom in sorted(poms):
        gid, aid, ver = infer_groupid_from_path(pom)
        if fix_pom(pom):
            fixed_count += 1
        else:
            # Print POMs that are OK for verification
            pass
    
    print(f"\nFixed {fixed_count} POM files")

if __name__ == '__main__':
    main()

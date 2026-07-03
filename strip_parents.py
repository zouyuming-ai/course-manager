#!/usr/bin/env python3
"""Strip parent blocks from all POM files in local-maven-repo."""
import os, re

REPO_DIR = "/Users/zouyuming/WorkBuddy/2026-06-27-13-26-33/course_manager/local-maven-repo"

for root, dirs, files in os.walk(REPO_DIR):
    for f in files:
        if f.endswith('.pom'):
            path = os.path.join(root, f)
            with open(path, 'r', encoding='utf-8') as fh:
                content = fh.read()
            if '<parent>' in content:
                content = re.sub(r'\s*<parent>.*?</parent>\s*', '\n', content, flags=re.DOTALL)
                with open(path, 'w', encoding='utf-8') as fh:
                    fh.write(content)
                print(f'Stripped parent from {os.path.relpath(path, REPO_DIR)}')

print('Done')

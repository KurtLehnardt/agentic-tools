#!/usr/bin/env python3
"""Static lint harness for the eval suite.

This harness validates the structural integrity of eval case definitions
and grader configurations. It catches two critical failure modes:

(1) tool_used graders with both min:0 and max:0 pass unconditionally,
    inflating case scores and hiding actual test failures. Two real eval
    runs failed silently because these graders were never triggered.

(2) criteria.md bullets asserting actions (Runs, Executes, Deploys, etc.)
    describe sandbox-impossible behaviors. When these assertions fail,
    the eval result is misleading — the case claims to test build but
    the sandbox cannot actually execute the build phase. Two real runs
    failed grading because assertions were satisfied by print statements
    instead of actual execution.

Run with --quiet to report only counts, or pass directory paths to lint
only those cases.
"""

import re
import json
import sys
import glob
import os
from pathlib import Path
from typing import List, Dict, Tuple, Set
import yaml

# Constants
CHECKS = {
    'structure': 0,
    'prompt_yaml': 0,
    'prompt_name': 0,
    'prompt_tools': 0,
    'grader_yaml': 0,
    'grader_regex': 0,
    'grader_tool_used': 0,
    'min_max_zero': 0,
    'exec_verbs': 0,
    'evals_json': 0,
}

ERRORS = []
WARNINGS = []

ALLOWED_PROMPT_KEYS = {'name', 'description', 'tags', 'allowed_tools', 'max_turns'}
REQUIRED_ALLOWED_TOOLS = ['Read', 'Glob', 'Grep', 'Skill']

EXEC_VERBS = r'^\s*-\s*(Runs|Executes|Deploys|Rolls back|Deletes|Removes|Applies|Installs|Commits|Pushes|Merges)\b'

# Matches in this set are NOT the defect: phrasal verbs with a different meaning, and the
# same tokens used as plural nouns followed by their own verb.
EXEC_VERB_FALSE_POSITIVES = r'^\s*-\s*(Pushes back\b|(Commits|Deletes|Removes|Merges)\s+(follow|lack|are|include|carry|use|contain)\b)'

def find_evals_root(search_paths: List[str] = None) -> str:
    """Find the evals directory root."""
    if search_paths and os.path.isdir(search_paths[0]):
        return search_paths[0]
    # Look for evals directory
    cwd = os.getcwd()
    if os.path.isdir(os.path.join(cwd, 'evals')):
        return os.path.join(cwd, 'evals')
    return 'evals'

def get_eval_cases(root_dir: str) -> List[Tuple[str, str]]:
    """Get all eval cases as (skill_dir, case_dir) tuples."""
    cases = []
    # Skip non-skill directories
    skip_dirs = {'results', 'lint.py', 'README.md', '.'}
    skill_dirs = glob.glob(os.path.join(root_dir, '*'))
    for skill_dir in skill_dirs:
        if not os.path.isdir(skill_dir):
            continue
        skill_name = os.path.basename(skill_dir)
        if skill_name in skip_dirs:
            continue
        # A dir holding prompt.md IS a case, not a skill dir -- this is how a scoped
        # invocation like `lint.py evals/deploy` is handled without shifting levels.
        if os.path.exists(os.path.join(skill_dir, 'prompt.md')):
            cases.append((os.path.basename(os.path.dirname(skill_dir)), skill_name, skill_dir))
            continue
        case_dirs = glob.glob(os.path.join(skill_dir, '*'))
        for case_dir in case_dirs:
            if os.path.isdir(case_dir) and os.path.basename(case_dir) != 'graders':
                case_name = os.path.basename(case_dir)
                cases.append((skill_name, case_name, case_dir))
    return cases

def check_structure(skill_name: str, case_name: str, case_dir: str) -> bool:
    """Check (a): directory has prompt.md and at least one grader."""
    prompt_path = os.path.join(case_dir, 'prompt.md')
    graders_dir = os.path.join(case_dir, 'graders')

    if not os.path.isfile(prompt_path):
        ERRORS.append(f"ERROR: {skill_name}/{case_name} missing prompt.md")
        return False

    if not os.path.isdir(graders_dir):
        ERRORS.append(f"ERROR: {skill_name}/{case_name} missing graders/ directory")
        return False

    grader_files = glob.glob(os.path.join(graders_dir, '*.md'))
    if not grader_files:
        ERRORS.append(f"ERROR: {skill_name}/{case_name}/graders has no files")
        return False

    CHECKS['structure'] += 1
    return True

def parse_frontmatter(content: str) -> Tuple[Dict, str]:
    """Parse YAML frontmatter and body from markdown."""
    if not content.startswith('---'):
        return {}, content

    parts = content.split('---', 2)
    if len(parts) < 3:
        return {}, content

    try:
        frontmatter = yaml.safe_load(parts[1])
        body = parts[2]
        return frontmatter or {}, body
    except yaml.YAMLError:
        return None, content

def check_prompt(skill_name: str, case_name: str, case_dir: str, prompt_names: Set[str]) -> bool:
    """Check (b): prompt frontmatter and body validity."""
    prompt_path = os.path.join(case_dir, 'prompt.md')

    try:
        with open(prompt_path, 'r') as f:
            content = f.read()
    except Exception as e:
        ERRORS.append(f"ERROR: {skill_name}/{case_name} cannot read prompt.md: {e}")
        return False

    frontmatter, body = parse_frontmatter(content)

    if frontmatter is None:
        ERRORS.append(f"ERROR: {skill_name}/{case_name} prompt.md YAML parse failed")
        CHECKS['prompt_yaml'] += 1
        return False

    CHECKS['prompt_yaml'] += 1

    # Check name format and uniqueness
    name = frontmatter.get('name')
    expected_name = f"{skill_name}-{case_name}"

    if not name:
        ERRORS.append(f"ERROR: {skill_name}/{case_name} prompt missing 'name'")
        return False

    if name != expected_name:
        ERRORS.append(f"ERROR: {skill_name}/{case_name} name '{name}' != '{expected_name}'")
        return False

    if name in prompt_names:
        ERRORS.append(f"ERROR: {skill_name}/{case_name} name '{name}' not globally unique")
        return False

    prompt_names.add(name)
    CHECKS['prompt_name'] += 1

    # Check keys are subset
    keys = set(frontmatter.keys())
    invalid_keys = keys - ALLOWED_PROMPT_KEYS
    if invalid_keys:
        ERRORS.append(f"ERROR: {skill_name}/{case_name} prompt has invalid keys: {invalid_keys}")
        return False

    # Check allowed_tools
    allowed_tools = frontmatter.get('allowed_tools', [])
    if allowed_tools != REQUIRED_ALLOWED_TOOLS:
        ERRORS.append(f"ERROR: {skill_name}/{case_name} allowed_tools {allowed_tools} != {REQUIRED_ALLOWED_TOOLS}")
        return False

    CHECKS['prompt_tools'] += 1

    # Check body non-empty
    if not body or not body.strip():
        ERRORS.append(f"ERROR: {skill_name}/{case_name} prompt body empty")
        return False

    return True

def check_graders(skill_name: str, case_name: str, case_dir: str) -> bool:
    """Check (c), (d), (e): grader files validity."""
    graders_dir = os.path.join(case_dir, 'graders')
    grader_files = glob.glob(os.path.join(graders_dir, '*.md'))

    all_valid = True

    for grader_path in grader_files:
        try:
            with open(grader_path, 'r') as f:
                content = f.read()
        except Exception as e:
            ERRORS.append(f"ERROR: {skill_name}/{case_name} cannot read {os.path.basename(grader_path)}: {e}")
            all_valid = False
            continue

        frontmatter, body = parse_frontmatter(content)

        if frontmatter is None:
            ERRORS.append(f"ERROR: {skill_name}/{case_name}/{os.path.basename(grader_path)} YAML parse failed")
            all_valid = False
            continue

        CHECKS['grader_yaml'] += 1

        # Check regex compilation for pattern and input_match
        for field in ['pattern', 'input_match']:
            regex_val = frontmatter.get(field)
            if regex_val:
                try:
                    re.compile(regex_val)
                except re.error as e:
                    ERRORS.append(f"ERROR: {skill_name}/{case_name}/{os.path.basename(grader_path)} {field} regex invalid: {e}")
                    all_valid = False

        CHECKS['grader_regex'] += 1

        # Check (c): tool_used grader with Skill must have arm:with-only and input_match with skill dir
        if frontmatter.get('type') == 'tool_used' and frontmatter.get('tool') == 'Skill':
            CHECKS['grader_tool_used'] += 1

            arm = frontmatter.get('arm')
            if arm != 'with-only':
                ERRORS.append(f"ERROR: {skill_name}/{case_name}/{os.path.basename(grader_path)} tool_used Skill missing arm:with-only")
                all_valid = False

            input_match = frontmatter.get('input_match', '')
            if skill_name not in input_match:
                ERRORS.append(f"ERROR: {skill_name}/{case_name}/{os.path.basename(grader_path)} tool_used Skill input_match missing skill name '{skill_name}'")
                all_valid = False

        # Check (d): tool_used with min:0 and max:0
        if frontmatter.get('type') == 'tool_used':
            min_val = frontmatter.get('min')
            max_val = frontmatter.get('max')
            if min_val == 0 and max_val == 0:
                ERRORS.append(f"ERROR: {skill_name}/{case_name}/graders/{os.path.basename(grader_path)} has min:0 and max:0 (inflates score)")
                CHECKS['min_max_zero'] += 1
                all_valid = False

        # Check (e): exec verbs in criteria.md
        #
        # Only PASS-section bullets are flagged. A FAIL-section bullet naming an action
        # ("Commits .env to git") asserts the reply must NOT propose it, which a judge can
        # still read off the text, so it is not the defect this check hunts.
        #
        # Two false-positive classes are excluded, because a check that fails correct work
        # causes workers to churn good rubrics:
        #   - phrasal verbs that are not the action ("Pushes back" is not `git push`)
        #   - the same words used as plural nouns ("Commits follow conventional format")
        if os.path.basename(grader_path) == 'criteria.md':
            in_fail = False
            for line in body.split('\n'):
                stripped = line.strip()
                low = stripped.lower()
                if low.startswith('pass if'):
                    in_fail = False
                    continue
                if low.startswith('fail if'):
                    in_fail = True
                    continue
                if in_fail:
                    continue
                if re.search(EXEC_VERB_FALSE_POSITIVES, stripped):
                    continue
                if re.search(EXEC_VERBS, line):
                    ERRORS.append(f"ERROR: {skill_name}/{case_name}/graders/criteria.md exec verb: {stripped}")
                    CHECKS['exec_verbs'] += 1
                    all_valid = False

    return all_valid

def check_evals_json(root_dir: str) -> bool:
    """Check (f): evals.json case count matches prompt.md files."""
    # Find skills root from evals root
    if root_dir.endswith('/evals') or root_dir == 'evals':
        parent_dir = os.path.dirname(root_dir) or '.'
    else:
        parent_dir = root_dir

    skills_root = os.path.join(parent_dir, 'skills')
    if not os.path.isdir(skills_root):
        skills_root = parent_dir

    all_valid = True
    # 'sandbox' is a real skill (evals/sandbox/, 6 cases), not a scratch directory.
    # Listing it here silently exempted an entire skill from the cross-format parity check.
    skip_dirs = {'results'}

    skill_dirs = glob.glob(os.path.join(skills_root, '*'))
    for skill_dir in skill_dirs:
        if not os.path.isdir(skill_dir):
            continue

        skill_name = os.path.basename(skill_dir)
        if skill_name in skip_dirs:
            continue

        evals_json_path = os.path.join(skill_dir, 'evals', 'evals.json')
        evals_dir = os.path.join(root_dir, skill_name)

        if not os.path.isdir(evals_dir):
            continue

        # Count prompt.md files
        prompt_files = glob.glob(os.path.join(evals_dir, '*/prompt.md'))
        prompt_count = len(prompt_files)

        if prompt_count == 0:
            continue

        # Parse evals.json if it exists
        if os.path.isfile(evals_json_path):
            try:
                with open(evals_json_path, 'r') as f:
                    evals_data = json.load(f)
                evals_count = len(evals_data.get('evals', []))
                if evals_count != prompt_count:
                    ERRORS.append(f"ERROR: skills/{skill_name}/evals/evals.json has {evals_count} cases but {prompt_count} prompt.md files")
                    all_valid = False
            except json.JSONDecodeError as e:
                ERRORS.append(f"ERROR: skills/{skill_name}/evals/evals.json JSON parse failed: {e}")
                all_valid = False
            except Exception as e:
                ERRORS.append(f"ERROR: skills/{skill_name}/evals/evals.json read failed: {e}")
                all_valid = False

        CHECKS['evals_json'] += 1

    return all_valid

def lint(search_paths: List[str] = None, quiet: bool = False) -> int:
    """Main lint function."""
    root_dir = find_evals_root(search_paths)

    if not os.path.isdir(root_dir):
        print(f"ERROR: {root_dir} not found", file=sys.stderr)
        return 1

    # Get eval cases
    cases = get_eval_cases(root_dir)

    # Track unique prompt names across all cases
    prompt_names: Set[str] = set()

    # Run checks
    for skill_name, case_name, case_dir in cases:
        check_structure(skill_name, case_name, case_dir)
        check_prompt(skill_name, case_name, case_dir, prompt_names)
        check_graders(skill_name, case_name, case_dir)

    # Check evals.json
    check_evals_json(root_dir)

    # Print results
    if not quiet:
        for error in ERRORS:
            print(error)
        for warning in WARNINGS:
            print(warning)

    # Print summary
    if not quiet and (ERRORS or WARNINGS):
        print()

    print(f"Checks: {sum(CHECKS.values())} total")
    print(f"  structure: {CHECKS['structure']}")
    print(f"  prompt_yaml: {CHECKS['prompt_yaml']}")
    print(f"  prompt_name: {CHECKS['prompt_name']}")
    print(f"  prompt_tools: {CHECKS['prompt_tools']}")
    print(f"  grader_yaml: {CHECKS['grader_yaml']}")
    print(f"  grader_regex: {CHECKS['grader_regex']}")
    print(f"  grader_tool_used: {CHECKS['grader_tool_used']}")
    print(f"  min_max_zero: {CHECKS['min_max_zero']}")
    print(f"  exec_verbs: {CHECKS['exec_verbs']}")
    print(f"  evals_json: {CHECKS['evals_json']}")
    print(f"Errors: {len(ERRORS)}")
    print(f"Warnings: {len(WARNINGS)}")

    return 1 if ERRORS else 0

if __name__ == '__main__':
    quiet = '--quiet' in sys.argv
    search_paths = [p for p in sys.argv[1:] if p != '--quiet']
    sys.exit(lint(search_paths, quiet))

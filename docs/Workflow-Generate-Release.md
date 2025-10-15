# Generate Release Workflow Documentation

**Workflow File:** `.github/workflows/generate-release.yml`

## Table of Contents

- [Purpose](#purpose)
- [Why This Exists](#why-this-exists)
- [When It Triggers](#when-it-triggers)
- [How It Works](#how-it-works)
  - [High-Level Process](#high-level-process)
  - [Detailed Steps](#detailed-steps)
- [Release Naming Convention](#release-naming-convention)
- [Environment-Specific Release Tracking](#environment-specific-release-tracking)
  - [Key Concept: Independent Release Histories](#key-concept-independent-release-histories)
  - [How It Works](#how-it-works-1)
  - [Why This Matters](#why-this-matters)
  - [Example Timeline](#example-timeline)
  - [Critical Point: Environment Releases Are Independent](#critical-point-environment-releases-are-independent)
  - [Key Takeaways](#key-takeaways)
- [Failure Recovery and Reliability](#failure-recovery-and-reliability)
  - [Always Runs on Merge](#always-runs-on-merge)
  - [Why This Matters](#why-this-matters-1)
  - [Checks Since Last Release](#checks-since-last-release)
  - [Catches Missed Changes](#catches-missed-changes)
  - [Graceful Exit](#graceful-exit)
  - [Example Scenario: Workflow Failure Recovery](#example-scenario-workflow-failure-recovery)
  - [Key Points](#key-points)
  - [Benefits of This Approach](#benefits-of-this-approach)
- [Release Artifacts](#release-artifacts)
  - [1. Compiled SQL File](#1-compiled-sql-file)
  - [2. ZIP Archive](#2-zip-archive)
  - [3. Release Notes](#3-release-notes)
- [Edge Cases Handled](#edge-cases-handled)
  - [No SQL Changes](#no-sql-changes)
  - [No Previous Release](#no-previous-release)
  - [Missing Semicolons](#missing-semicolons)
  - [Multi-line Commit Messages](#multi-line-commit-messages)
  - [Special Characters in Commit Messages](#special-characters-in-commit-messages)
- [Configuration](#configuration)
  - [Branch Targets](#branch-targets)
  - [Schema Folders](#schema-folders)
  - [Excluded Paths](#excluded-paths)
- [Integration with Existing Systems](#integration-with-existing-systems)
  - [Jira Integration](#jira-integration)
  - [Existing Release Note System](#existing-release-note-system)
- [Troubleshooting](#troubleshooting)
  - [Release Not Created](#release-not-created)
  - [Incorrect File Ordering](#incorrect-file-ordering)
  - [Workflow Fails](#workflow-fails)
- [Performance Characteristics](#performance-characteristics)
- [Security Considerations](#security-considerations)
  - [Permissions Required](#permissions-required)
  - [Input Sanitization](#input-sanitization)
  - [Branch Protection](#branch-protection)
- [Benefits](#benefits)
- [Related Workflows](#related-workflows)
- [Maintenance](#maintenance)
  - [Updating Release Format](#updating-release-format)
  - [Changing Tag Format](#changing-tag-format)
  - [Adding New Metadata](#adding-new-metadata)
- [Version History](#version-history)

## Purpose

This workflow automatically generates database changelog releases when changes are promoted between environments. It compiles all SQL changes since the last release into a single deployable file, making it easy for managers to execute database updates in the target environment.

## Why This Exists

**Problem Solved:**
- Manual tracking of database changes is error-prone and time-consuming
- Database changes were frequently missed during environment promotions
- No automated way to compile multiple SQL files into a deployment-ready format
- Lack of integration with existing release note systems

**Solution Provided:**
- Automatic detection of new SQL changes on merge
- Chronological ordering based on Git commit timestamps
- Single compiled SQL file ready for copy-paste execution
- Integration with GitHub Releases and release notes
- Audit trail with commit messages and metadata

## When It Triggers

**Trigger Event:** Push to `qa` or `prod` branches (not filtered by file changes)

**Why Not Filtered:** Running on every push ensures that changes missed by previous workflow failures (GitHub Actions outages, permission issues, etc.) are caught on the next push. The workflow checks for SQL files since the last successful release, not just changes in the current push.

**Conditions:**
- Triggers on EVERY push to `qa` or `prod` branches, regardless of which files changed
- Checks for SQL files added since the last successful release for that environment
- If no SQL files are found, exits gracefully without creating a release
- Runs automatically on merge (no manual intervention needed)

**Example Triggering Scenarios:**
- Manager merges PR from `dev` → `qa` (triggers for QA release)
- Manager merges PR from `qa` → `prod` (triggers for PROD release)
- Direct push to `qa` or `prod` branch, even with only documentation changes (triggers but may exit if no SQL files since last release)

## How It Works

### High-Level Process

1. **Environment Detection**: Determines environment from branch name (qa/prod)
2. **Find Last Release**: Looks for previous release tag for this environment
3. **Get Changed Files**: Uses `git diff` to find SQL files added since last release
4. **Order by Commit Timestamp**: Sorts files chronologically using Git commit timestamps
5. **Generate Compiled SQL**: Creates single file with all changes and metadata
6. **Create ZIP Archive**: Packages individual SQL files preserving folder structure
7. **Create GitHub Release**: Publishes release with tag, notes, and downloadable assets
8. **Comment on PR**: If merge came from a pull request, posts a comment with release link and deployment instructions

### Detailed Steps

#### Step 1: Environment Detection
```yaml
BRANCH_NAME="${REF_NAME#refs/heads/}"
ENV_UPPER=$(echo $BRANCH_NAME | tr '[:lower:]' '[:upper:]')  # QA, PROD
ENV_LOWER=$BRANCH_NAME  # qa, prod
```

#### Step 2: Find Last Release
```bash
# Find last release tag for THIS ENVIRONMENT ONLY
LAST_TAG=$(git tag -l "${ENV_LOWER}-*" --sort=-version:refname | head -1)

# Examples:
# - If environment is "qa", looks ONLY for tags like: qa-2025.10.15.1430
# - If environment is "prod", looks ONLY for tags like: prod-2025.10.16.0930
# - The ${ENV_LOWER}-* filter ensures QA releases ignore PROD tags and vice versa
# - If no previous release for this environment, uses repository start (first commit)
```

**Critical:** The `${ENV_LOWER}-*` pattern ensures environment-specific filtering:
- QA workflow searches for `qa-*` tags only (ignores `prod-*`)
- PROD workflow searches for `prod-*` tags only (ignores `qa-*`)
- Each environment maintains independent release history

See the "Environment-Specific Release Tracking" section below for detailed explanation of why this matters.

#### Step 3: Get Changed SQL Files
```bash
# Get all SQL files added since last release
git diff --name-only --diff-filter=A "$SINCE"...HEAD -- "*.sql"

# Filters:
# - Only added files (--diff-filter=A)
# - Only .sql files
# - Excludes .github/ and docs/ folders
```

#### Step 4: Order Files by Commit Timestamp
```bash
# For each SQL file, get Unix timestamp when it was first committed
timestamp=$(git log --diff-filter=A --format=%at --all -- "$file" | head -1)

# Sort files numerically by timestamp
sort -n

# Result: Files ordered chronologically regardless of filename
```

#### Step 5: Generate Compiled SQL File
```sql
-- ============================================
-- DATABASE CHANGELOG RELEASE
-- Environment: QA
-- Generated: 2025-10-15 14:30:00 UTC
-- Release Tag: qa-2025.10.15.1430
-- Changes Since: qa-2025.10.14.0900
-- ============================================

-- ============================================
-- Change 1 of 3
-- File: auth/add_mfa_column.sql
-- Committed: 2025-10-15 10:15:30 -0400
-- Commit: a1b2c3d
-- Message: PROJ-1234: Add MFA column to user table
-- ============================================
ALTER TABLE users
ADD COLUMN mfa_enabled TINYINT(1) DEFAULT 0 NOT NULL;

-- (Ensures semicolon terminator)
;

-- ============================================
-- Change 2 of 3
-- ...
```

**Key Features of Compiled SQL:**
- Global header with release metadata
- Per-change headers with file path, commit info, and commit message
- Original SQL content preserved
- Automatic semicolon addition if missing (prevents execution errors)
- Multi-line commit messages properly formatted with comment prefixes
- Blank lines between statements for readability

#### Step 6: Create ZIP Archive
```bash
# Create ZIP with all individual SQL files
zip -r "database-changelog-${RELEASE_TAG}.zip" \
  auth/ application/ integrations/ tenants/ \
  -i "*.sql"

# Preserves folder structure:
# - auth/file1.sql
# - integrations/file2.sql
# - etc.
```

#### Step 7: Create GitHub Release
```yaml
- uses: softprops/action-gh-release@v2
  with:
    tag_name: qa-2025.10.15.1430           # Unique tag for this release
    name: QA - 2025.10.15.1430             # Human-readable release name
    generate_release_notes: true            # Auto-generate from commits
    files: |
      database-changelog-qa-2025.10.15.1430.sql
      database-changelog-qa-2025.10.15.1430.zip
```

#### Step 8: Comment on PR with Release Link
```bash
# Extract PR number from commit message if this was a merge
# Example: "Merge pull request #123 from..." → PR #123
PR_NUMBER=$(git log -1 --format=%s | grep -oP "Merge pull request #\K\d+")

if [ -n "$PR_NUMBER" ]; then
  # Post comment with release details to the PR
  gh pr comment "$PR_NUMBER" --body "..."
fi
```

**What the PR Comment Includes:**
- Direct link to the release
- Release tag and environment
- List of release assets (compiled SQL, ZIP, release notes)
- Next steps for deployment

**Example PR Comment:**
```markdown
## 🚀 Database Changelog Release Created

**Release:** [QA - 2025.10.15.1430](https://github.com/owner/repo/releases/tag/qa-2025.10.15.1430)
**Environment:** QA
**Tag:** `qa-2025.10.15.1430`

### 📦 Release Assets

The following files are ready for deployment:

1. **Compiled SQL File** - Main deployment file
2. **ZIP Archive** - Individual SQL files
3. **Release Notes** - Auto-generated from commits

### ⬇️ Next Steps

1. Download the compiled SQL file from the release
2. Review the SQL statements
3. Execute in the QA database
4. Verify changes in QA
```

**Benefits of PR Comments:**
- Users stay in their PR workflow without navigating to Releases page
- Immediate feedback after merge
- Clear deployment instructions
- Direct link to the exact release generated from this PR

## Release Naming Convention

**Tag Format:** `{environment}-{YYYY}.{MM}.{DD}.{HHMM}`

**Examples:**
- `qa-2025.10.15.1430` - QA release on Oct 15, 2025 at 2:30 PM UTC
- `prod-2025.10.16.0930` - PROD release on Oct 16, 2025 at 9:30 AM UTC

**Why This Format:**
- Lowercase environment for Git tag compatibility
- Date-based for chronological sorting
- 24-hour time format (no colons for compatibility)
- Unique and human-readable

## Environment-Specific Release Tracking

### Key Concept: Independent Release Histories

**Each environment (dev, qa, prod) maintains its own completely independent release history.**

This is a critical aspect of how the release workflow operates and is essential to understanding what changes will be included in any given release.

### How It Works

When the workflow generates a release, it only searches for tags matching that specific environment's prefix:

- **QA releases** → Search for `qa-*` tags only
- **PROD releases** → Search for `prod-*` tags only
- **DEV releases** → Search for `dev-*` tags only

The workflow finds the most recent tag for the target environment and includes all SQL changes committed since that tag.

**Code Reference (Step 2):**
```bash
# Find last release tag for THIS environment only
LAST_TAG=$(git tag -l "${ENV_LOWER}-*" --sort=-version:refname | head -1)
```

The `${ENV_LOWER}-*` filter ensures QA releases ignore PROD tags and vice versa.

### Why This Matters

This design ensures correct change tracking across environments, preventing:
- Duplicate deployments (same changes released twice)
- Missing changes (changes skipped because they were "already released" in another environment)
- Confusion about what's actually in each environment

### Example Timeline

```
Timeline of Events:

1. qa-2025.10.15.1430 created
   - QA release with changes A, B, C

2. qa-2025.10.15.1600 created
   - QA release with changes D, E

3. prod-2025.10.16.0930 created
   - First PROD release
   - Includes changes A, B, C, D, E (everything since repo start)

Next PROD Release:
- Searches for last "prod-*" tag → finds prod-2025.10.16.0930
- Includes all changes committed AFTER prod-2025.10.16.0930
- Completely ignores all QA release tags:
  - qa-2025.10.15.1430 ❌ Not considered
  - qa-2025.10.15.1600 ❌ Not considered
- If new changes F, G exist, creates prod-2025.10.16.1200 with changes F, G only
```

### Critical Point: Environment Releases Are Independent

**QA having 10 releases does not affect what goes into the next PROD release.**

PROD only cares about:
- What was in the last PROD release (`prod-*` tag)
- What has changed since then in Git

Example scenarios:

**Scenario 1: QA releases frequently, PROD releases infrequently**
```
QA releases: qa-001, qa-002, qa-003, qa-004, qa-005 (5 releases)
PROD releases: prod-001 (1 release)

Next PROD release will include:
- Everything committed after prod-001
- Ignores that QA has 5 releases
- Could be 0 changes or 100 changes, depending on Git history
```

**Scenario 2: PROD catches up to QA**
```
QA releases: qa-001 (changes A, B, C)
PROD releases: prod-001 (changes A, B, C)

Next PROD release will include:
- Only changes committed after prod-001
- NOT "whatever is in the next QA release"
- Environments are now "in sync" but continue to track independently
```

**Scenario 3: Hotfix goes directly to PROD**
```
QA releases: qa-001 (changes A, B, C)
PROD releases: prod-001 (changes A, B, C, D)  ← includes hotfix D that skipped QA

Next PROD release:
- Searches from prod-001
- Includes changes after prod-001
- Change D was already in PROD, won't appear again

Next QA release:
- Searches from qa-001
- Includes changes after qa-001 (might include D if it was committed to qa branch later)
- Independent of PROD's history
```

### Key Takeaways

1. **Each environment has its own "last release" pointer** - PROD doesn't care about QA's releases and vice versa
2. **The number of releases in one environment is irrelevant to other environments** - 1 QA release or 100 QA releases, PROD still tracks from its last PROD release
3. **Changes are tracked by Git commits, not by releases** - What matters is what commits exist between the last release tag and HEAD
4. **First release for an environment includes everything** - If PROD has never been released, the first release includes all SQL files in the repository
5. **This prevents deployment confusion** - You can't accidentally skip changes or deploy them twice because each environment tracks its own state

## Failure Recovery and Reliability

### Always Runs on Merge

The workflow triggers on EVERY push to `qa` or `prod` branches, regardless of which files were changed in that specific push. This design choice is critical for reliability and automatic failure recovery.

### Why This Matters

If a previous workflow run failed (due to GitHub Actions outage, permission issues, transient network errors, etc.), the next push to the branch will still trigger the workflow. This ensures that changes are never permanently missed due to infrastructure failures.

### Checks Since Last Release

The workflow doesn't just check for SQL files in the current push. Instead, it:

1. Finds the last successful release tag for the target environment (e.g., `qa-2025.10.14.0900`)
2. Compares HEAD against that tag using `git diff`
3. Includes ALL SQL files added since that last successful release

This means the workflow catches changes from previous pushes that may have been missed due to workflow failures.

### Catches Missed Changes

If SQL files were added in a previous push but the workflow failed to create a release, the next workflow run will detect and include those files. This provides automatic self-healing without manual intervention.

### Graceful Exit

If the workflow runs but finds no SQL files have been added since the last successful release, it exits gracefully without creating an empty release. This prevents noise from documentation-only or configuration-only changes.

### Example Scenario: Workflow Failure Recovery

```
Timeline:

1. PR #1 merged to qa branch (2025-10-15 14:00 UTC)
   - Contains SQL files: auth/add_mfa_column.sql, integrations/add_metric.sql
   - Workflow starts executing
   - GitHub Actions experiences an outage mid-execution
   - Workflow fails, no release created
   - Last successful release remains: qa-2025.10.14.0900

2. PR #2 merged to qa branch (2025-10-15 15:30 UTC)
   - Contains ONLY documentation changes (docs/README.md updated)
   - No SQL files in this PR
   - Workflow still runs (not filtered by file paths)
   - Workflow checks: "What SQL files exist since qa-2025.10.14.0900?"
   - Finds: auth/add_mfa_column.sql, integrations/add_metric.sql (from PR #1!)
   - Creates release: qa-2025.10.15.1530
   - Release includes the two SQL files from PR #1 that were missed
   - **Automatic recovery complete - no manual intervention needed**

3. PR #3 merged to qa branch (2025-10-15 16:00 UTC)
   - Contains SQL file: application/add_user_table.sql
   - Workflow runs
   - Workflow checks: "What SQL files exist since qa-2025.10.15.1530?"
   - Finds: application/add_user_table.sql (only the new file)
   - Creates release: qa-2025.10.15.1600
   - Release includes only the one file from PR #3
   - Previous files (from PR #1) were already in qa-2025.10.15.1530, not duplicated
```

### Key Points

1. **Every push triggers the workflow** - Even documentation-only changes trigger the check
2. **Workflow looks backward from last success** - Not just at current push changes
3. **Missed files are automatically caught** - Next successful run includes everything since last successful release
4. **No duplicates** - Once a file is included in a release, it won't appear in subsequent releases
5. **Zero manual intervention** - System self-heals without human action

### Benefits of This Approach

- **Resilience**: Infrastructure failures don't result in permanent data loss
- **Simplicity**: No need to track "which workflow runs failed" or manually trigger re-runs
- **Consistency**: Every successful release represents the complete set of changes since the previous successful release
- **Audit Trail**: Release history remains complete even when individual workflow runs fail

## Release Artifacts

Each release includes three downloadable files:

### 1. Compiled SQL File
**Filename:** `database-changelog-{tag}.sql`

**Purpose:** Main deployment file for copy-paste execution in target database

**Contents:**
- All SQL changes in chronological order
- Metadata headers for each change
- Commit messages for context
- Automatic semicolon terminators

**Usage:** Download and execute in target database environment

### 2. ZIP Archive
**Filename:** `database-changelog-{tag}.zip`

**Purpose:** Reference and audit trail

**Contents:**
- All individual SQL files
- Original folder structure preserved
- Useful for reviewing individual changes

**Usage:** Extract to see individual files if needed for selective application or review

### 3. Release Notes
**Location:** GitHub Release description

**Purpose:** Context from Git commit messages

**Contents:**
- Auto-generated from commits between releases
- Includes Jira references (e.g., PROJ-1234)
- Shows what changed and why

**Usage:** Review to understand what's in the release before executing

## Edge Cases Handled

### No SQL Changes
If no SQL files have been added since the last release, the workflow silently exits without creating a release. This prevents empty releases.

### No Previous Release
If this is the first release for an environment, the workflow uses the repository's first commit as the starting point, including all SQL files ever committed.

### Missing Semicolons
The workflow automatically adds semicolons to statements that don't end with one, preventing SQL execution errors.

### Multi-line Commit Messages
Commit messages with multiple lines are properly formatted with comment prefixes on continuation lines:
```sql
-- Message: PROJ-1234: Add feature
--          This is a detailed explanation
--          that spans multiple lines
```

### Special Characters in Commit Messages
All special characters are safe in SQL comments. Only newlines are converted to maintain comment integrity.

## Configuration

### Branch Targets
To change which branches trigger releases, modify:
```yaml
on:
  push:
    branches:
      - qa
      - prod
```

### Schema Folders
The workflow automatically includes all folders containing `.sql` files. No configuration needed.

### Excluded Paths
Files in these locations are never included:
```yaml
paths:
  - '!.github/**'  # Workflow files
  - '!docs/**'     # Documentation
```

## Integration with Existing Systems

### Jira Integration
Commit messages with Jira references (e.g., "PROJ-1234: ...") automatically appear in:
- Compiled SQL file headers
- GitHub Release notes
- Existing release note generation systems

### Existing Release Note System
Since database changes are now in Git:
- Existing release note generators can include this repository
- Database changes appear alongside code changes
- Unified view of all environment promotion changes

## Troubleshooting

### Release Not Created
**Symptoms:** No release appears after merge

**Possible Causes:**
1. No SQL files were changed (check with `git diff`)
2. SQL files only modified, not added (workflow uses `--diff-filter=A`)
3. Changes were in excluded folders (`.github/`, `docs/`)

**Solution:** Verify SQL files were added (not just modified) and are in schema folders

### Incorrect File Ordering
**Symptoms:** Files appear in wrong order in compiled SQL

**Cause:** Git commit timestamps are used, not filenames

**Solution:** This is working as designed. Files are ordered by when they were committed to Git, ensuring dependencies work correctly. If a file needs to run first, commit it first.

### Workflow Fails
**Symptoms:** Workflow shows error status

**Check:**
1. GitHub Actions logs for specific error message
2. SQL syntax validation workflow (may have caught syntax errors)
3. Permissions (workflow needs `contents: write` to create releases)

## Performance Characteristics

- **Execution Time:** Typically < 2 minutes
- **Scales To:** Thousands of SQL files (limited by GitHub Actions)
- **Storage:** Release artifacts stored indefinitely in GitHub Releases

## Security Considerations

### Permissions Required
```yaml
permissions:
  contents: write       # Required to create releases and tags
  pull-requests: write  # Required to comment on pull requests
```

### Input Sanitization
- Commit messages are sanitized to prevent SQL comment breakout
- File paths are validated
- No user input directly interpolated in bash

### Branch Protection
Workflow relies on branch protection rules for `qa` and `prod` to ensure:
- Only authorized personnel can trigger releases
- Pull requests are reviewed before merge
- Required status checks pass

## Benefits

1. **Eliminates Manual Tracking**: No more local lists or spreadsheets
2. **Prevents Missed Changes**: All changes automatically detected
3. **Ensures Correct Order**: Git timestamps handle dependencies
4. **Provides Context**: Commit messages explain why each change was made
5. **Integrates with Tools**: Works with existing Jira and release note systems
6. **Creates Audit Trail**: Every release has complete history
7. **Reduces Errors**: Automatic semicolon addition prevents syntax errors
8. **Saves Time**: One-click download and execute vs manual compilation
9. **In-PR Notifications**: Automatic PR comments with release links keep users in their workflow
10. **Immediate Feedback**: Users see release details instantly after merge without searching Releases page
11. **Automatic Failure Recovery**: Runs on every merge to catch changes missed by previous workflow failures, with no manual intervention required

## Related Workflows

- **Manual Release Generation** (`manual-release.yml`) - For on-demand releases with date ranges
- **SQL Syntax Validation** (`validate-sql-syntax.yml`) - Validates SQL before it gets to releases

## Maintenance

### Updating Release Format
To change the compiled SQL format, modify the "Generate compiled SQL file" step:
```bash
cat >> "$OUTPUT_FILE" << EOF
-- Your custom header format
EOF
```

### Changing Tag Format
To modify release tag naming:
```bash
TAG_DATE=$(date -u +"%Y.%m.%d.%H%M")  # Current format
RELEASE_TAG="${ENV_LOWER}-${TAG_DATE}"
```

### Adding New Metadata
To include additional metadata in compiled SQL headers:
```bash
# Get additional info
author=$(git log -1 --format=%an "$commit_hash" -- "$file")

# Add to header
cat >> "$OUTPUT_FILE" << EOF
-- Author: $author
EOF
```

## Version History

- **Initial Version (2025-10-15)**: Basic release generation with commit timestamps
- **Added Multi-line Messages (2025-10-15)**: Support for multi-line commit messages
- **Added Semicolon Handling (2025-10-15)**: Automatic semicolon addition
- **Added PR Comment Feature (2025-10-15)**: Automatically comments on PRs with release link and deployment instructions

---

**Last Updated:** 2025-10-15
**Workflow Version:** 1.0
**Status:** Production Ready

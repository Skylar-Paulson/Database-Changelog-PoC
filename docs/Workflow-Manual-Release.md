# Manual Release Generation Workflow Documentation

**Workflow File:** `.github/workflows/manual-release.yml`

## Table of Contents

- [Purpose](#purpose)
- [Why This Exists](#why-this-exists)
- [When It Triggers](#when-it-triggers)
- [Input Parameters](#input-parameters)
  - [1. Environment (Required)](#1-environment-required)
  - [2. Since Date (Optional)](#2-since-date-optional)
  - [3. Since Tag (Optional)](#3-since-tag-optional)
- [How It Works](#how-it-works)
  - [High-Level Process](#high-level-process)
  - [Detailed Steps](#detailed-steps)
- [Use Cases](#use-cases)
  - [Use Case 1: Dev Environment Release](#use-case-1-dev-environment-release)
  - [Use Case 2: Emergency Hotfix](#use-case-2-emergency-hotfix)
  - [Use Case 3: Specific Date Range](#use-case-3-specific-date-range)
  - [Use Case 4: Regenerate Release](#use-case-4-regenerate-release)
- [Input Combinations](#input-combinations)
- [Differences from Automatic Workflow](#differences-from-automatic-workflow)
  - [Similarities](#similarities)
  - [Differences](#differences)
- [Edge Cases Handled](#edge-cases-handled)
  - [No Changes Found](#no-changes-found)
  - [Invalid Date](#invalid-date)
  - [Invalid Tag](#invalid-tag)
  - [Future Date](#future-date)
- [Release Naming](#release-naming)
- [Configuration](#configuration)
  - [Add New Environment](#add-new-environment)
  - [Change Validation Logic](#change-validation-logic)
- [Permissions Required](#permissions-required)
  - [Workflow Permissions](#workflow-permissions)
  - [User Permissions](#user-permissions)
- [Troubleshooting](#troubleshooting)
  - ["No SQL files found since {date/tag}"](#no-sql-files-found-since-datetag)
  - ["Invalid date format"](#invalid-date-format)
  - ["Tag does not exist"](#tag-does-not-exist)
  - [Workflow Doesn't Appear in UI](#workflow-doesnt-appear-in-ui)
- [Security Considerations](#security-considerations)
  - [Input Validation](#input-validation)
  - [No Direct User Input in Commands](#no-direct-user-input-in-commands)
  - [Branch Protection](#branch-protection)
- [Best Practices](#best-practices)
  - [When to Use Manual Workflow](#when-to-use-manual-workflow)
  - [Recommended Workflow](#recommended-workflow)
- [Integration with Other Workflows](#integration-with-other-workflows)
  - [SQL Syntax Validation](#sql-syntax-validation)
  - [Automatic Release Generation](#automatic-release-generation)
- [Performance](#performance)
- [Related Workflows](#related-workflows)
- [Examples](#examples)
  - [Example 1: Dev Release (All Changes)](#example-1-dev-release-all-changes)
  - [Example 2: QA Release (Last Week)](#example-2-qa-release-last-week)
  - [Example 3: Prod Hotfix (Since Last Release)](#example-3-prod-hotfix-since-last-release)
- [Maintenance](#maintenance)
  - [Updating Input Options](#updating-input-options)
  - [Changing Default Environment](#changing-default-environment)
- [Version History](#version-history)

## Purpose

This workflow allows authorized users to manually generate database changelog releases on-demand with custom date ranges or tags. It's primarily used for emergency hotfixes, dev environment releases, or generating releases for specific time periods.

## Why This Exists

**Problem Solved:**
- Automatic workflow only triggers on merge to `qa`/`prod`
- Dev environment needs releases but doesn't require PRs
- Emergency hotfixes need releases outside normal promotion flow
- Need to regenerate releases for specific date ranges
- Want to create releases for testing purposes

**Solution Provided:**
- Manual trigger via GitHub Actions UI
- Flexible date range selection
- Support for all three environments (dev/qa/prod)
- Same compilation logic as automatic workflow
- Can work from any branch

## When It Triggers

**Trigger Event:** Manual dispatch via GitHub Actions UI

**How to Trigger:**
1. Go to GitHub repository
2. Click "Actions" tab
3. Select "Manual Database Changelog Release" workflow
4. Click "Run workflow" button
5. Fill in inputs (environment, optional date/tag)
6. Click "Run workflow"

**No Automatic Triggers:** This workflow only runs when manually invoked.

## Input Parameters

### 1. Environment (Required)
**Input Name:** `environment`

**Type:** Choice (dropdown)

**Options:**
- `dev` - Development environment
- `qa` - QA environment
- `prod` - Production environment

**Default:** `dev`

**Purpose:** Specifies which environment this release is for

**Example:** Select `qa` to generate a QA release

### 2. Since Date (Optional)
**Input Name:** `since_date`

**Type:** String

**Format:** `YYYY-MM-DD`

**Purpose:** Generate release with changes since this date

**Example:** `2025-10-01` includes all changes committed on or after October 1, 2025

**Notes:**
- Leave blank to use last release tag
- Cannot be used with `since_tag`
- If provided, overrides `since_tag`

### 3. Since Tag (Optional)
**Input Name:** `since_tag`

**Type:** String

**Format:** `{env}-{YYYY}.{MM}.{DD}.{HHMM}`

**Purpose:** Generate release with changes since this specific release

**Example:** `qa-2025.10.01.0900` includes all changes after this QA release

**Notes:**
- Leave blank to use last release tag
- Cannot be used with `since_date`
- Tag must exist in repository
- `since_date` takes precedence if both provided

## How It Works

### High-Level Process

1. **Validate Inputs**: Checks environment, date format, and tag existence
2. **Determine Start Point**: Uses date, tag, or last release as starting point
3. **Get Changed Files**: Finds SQL files added since start point
4. **Order by Commit Timestamp**: Sorts files chronologically
5. **Generate Compiled SQL**: Creates single file with metadata
6. **Create ZIP Archive**: Packages individual files
7. **Create GitHub Release**: Publishes release with assets

### Detailed Steps

#### Step 1: Validate Inputs

**Environment Validation:**
```bash
if [[ ! "$ENVIRONMENT" =~ ^(dev|qa|prod)$ ]]; then
  echo "Error: Invalid environment. Must be dev, qa, or prod."
  exit 1
fi
```

**Date Validation (if provided):**
```bash
if ! date -d "$SINCE_DATE" >/dev/null 2>&1; then
  echo "Error: Invalid date format. Use YYYY-MM-DD"
  exit 1
fi
```

**Tag Validation (if provided):**
```bash
if ! git rev-parse "$SINCE_TAG" >/dev/null 2>&1; then
  echo "Error: Tag $SINCE_TAG does not exist"
  exit 1
fi
```

#### Step 2: Determine Start Point

**Priority Order:**
1. If `since_date` provided: Use commit at that date
2. Else if `since_tag` provided: Use that tag
3. Else: Use last release tag for environment
4. If no previous release: Use repository start

**Date Lookup:**
```bash
# Find first commit on or before the specified date
SINCE_COMMIT=$(git rev-list -1 --before="$SINCE_DATE" HEAD)
```

**Tag Lookup:**
```bash
# Use the provided tag
SINCE_COMMIT=$(git rev-parse "$SINCE_TAG")
```

**Last Release Lookup:**
```bash
# Find most recent release for this environment
LAST_TAG=$(git tag -l "${ENV_LOWER}-*" --sort=-version:refname | head -1)
```

#### Step 3-7: Same as Automatic Workflow

The remaining steps (Get Changed Files, Order Files, Generate SQL, Create ZIP, Create Release) use the exact same logic as the automatic workflow.

See [Workflow-Generate-Release.md](./Workflow-Generate-Release.md) for details.

## Use Cases

### Use Case 1: Dev Environment Release

**Scenario:** Developer wants to test the full release workflow with dev changes

**Steps:**
1. Open GitHub Actions → Manual Database Changelog Release
2. Select Environment: `dev`
3. Leave date/tag blank (uses all dev changes)
4. Click "Run workflow"

**Result:** Creates release with all SQL files in dev branch

### Use Case 2: Emergency Hotfix

**Scenario:** Critical bug fix needs immediate release to prod, bypassing normal promotion flow

**Steps:**
1. Create hotfix SQL file in `prod` branch
2. Commit and push
3. Open GitHub Actions → Manual Database Changelog Release
4. Select Environment: `prod`
5. Since Tag: `prod-2025.10.15.1430` (last prod release)
6. Click "Run workflow"

**Result:** Creates release with only the hotfix changes

### Use Case 3: Specific Date Range

**Scenario:** Need to regenerate QA release for October 1-15

**Steps:**
1. Open GitHub Actions → Manual Database Changelog Release
2. Select Environment: `qa`
3. Since Date: `2025-10-01`
4. Click "Run workflow"

**Result:** Creates release with all QA changes since October 1

### Use Case 4: Regenerate Release

**Scenario:** Previous release had an issue, need to regenerate

**Steps:**
1. Open GitHub Actions → Manual Database Changelog Release
2. Select Environment: `qa`
3. Since Tag: `qa-2025.10.10.0900` (start from this release)
4. Click "Run workflow"

**Result:** Creates new release with same changes, new tag

## Input Combinations

| Environment | Since Date | Since Tag | Result |
|-------------|------------|-----------|--------|
| qa | (blank) | (blank) | All changes since last qa release |
| dev | 2025-10-01 | (blank) | All dev changes since Oct 1 |
| prod | (blank) | prod-2025.10.15.1430 | All prod changes since that tag |
| qa | 2025-10-01 | qa-2025.09.01.1200 | Date takes precedence (Oct 1) |

## Differences from Automatic Workflow

### Similarities
- Same SQL compilation logic
- Same file ordering (Git commit timestamp)
- Same release artifact format
- Same semicolon handling
- Same multi-line commit message support

### Differences

| Aspect | Automatic Workflow | Manual Workflow |
|--------|-------------------|-----------------|
| **Trigger** | Push to qa/prod | Manual dispatch |
| **Environments** | qa, prod only | dev, qa, prod |
| **Start Point** | Last release or repo start | Date, tag, or last release |
| **Use Case** | Normal promotions | Hotfixes, dev releases, custom ranges |
| **Branch** | Triggered branch | Any branch (runs on default) |
| **Error Handling** | Silent skip if no changes | Fails loudly if no changes |

## Edge Cases Handled

### No Changes Found

**Automatic Workflow:** Silently exits (no release created)

**Manual Workflow:** Fails with error message

**Reason:** Manual triggers are intentional - user should know if there are no changes

### Invalid Date
```
Error: Invalid date format. Use YYYY-MM-DD
Example: 2025-10-15
```

### Invalid Tag
```
Error: Tag qa-2025.10.99.9999 does not exist
```

### Future Date
```
Error: Date 2026-01-01 is in the future
```

## Release Naming

**Same as Automatic Workflow:**

Tag: `{environment}-{current-date-time}`

Example: `qa-2025.10.15.1445` (released at 2:45 PM on Oct 15)

**Note:** The tag reflects when the release was *generated*, not the date range of changes.

## Configuration

### Add New Environment

To add a new environment option:
```yaml
inputs:
  environment:
    type: choice
    options:
      - dev
      - qa
      - prod
      - staging  # Add new option
```

### Change Validation Logic

To modify date/tag validation:
```bash
# In "Validate and determine start point" step
# Add custom validation here
```

## Permissions Required

### Workflow Permissions
```yaml
permissions:
  contents: write  # Create releases and tags
```

### User Permissions

To run this workflow, users need:
- Write access to repository (to trigger workflow)
- Actions permissions (to execute workflows)

**Recommendation:** Restrict via branch protection and team permissions

## Troubleshooting

### "No SQL files found since {date/tag}"

**Cause:** No SQL files were added in the specified range

**Solution:**
- Verify date/tag is correct
- Check that SQL files exist in schema folders
- Ensure files were added (not just modified)

### "Invalid date format"

**Cause:** Date not in YYYY-MM-DD format

**Solution:** Use format like `2025-10-15`

### "Tag does not exist"

**Cause:** Specified tag hasn't been created yet

**Solution:**
- Check existing tags: `git tag -l`
- Use a valid tag or leave blank

### Workflow Doesn't Appear in UI

**Cause:** Workflow file not in default branch

**Solution:** Ensure `manual-release.yml` is committed to default branch (usually `main` or `master`)

## Security Considerations

### Input Validation

All inputs are validated before execution:
- Environment: Must be dev/qa/prod
- Date: Must be valid date format
- Tag: Must exist in repository

### No Direct User Input in Commands

All inputs are assigned to environment variables first:
```yaml
env:
  ENVIRONMENT: ${{ inputs.environment }}  # Sanitized via env vars
run: echo "$ENVIRONMENT"  # Safe
```

### Branch Protection

While this workflow can run from any branch, it still respects:
- Release permissions (needs write access)
- GitHub Actions permissions
- Branch protection rules for targeted environment

## Best Practices

### When to Use Manual Workflow

✅ **Good Use Cases:**
- Emergency hotfixes bypassing normal flow
- Dev environment releases (dev doesn't require PRs)
- Regenerating releases with specific date ranges
- Testing release process
- Creating releases for demonstrations

❌ **Avoid Using For:**
- Normal qa/prod promotions (use automatic workflow)
- Regular scheduled releases (defeats automation purpose)
- When unclear what changes are included (use automatic workflow for safety)

### Recommended Workflow

**Normal Promotion (use automatic):**
```
dev → PR → qa (automatic release)
qa → PR → prod (automatic release)
```

**Hotfix (use manual):**
```
prod branch → hotfix commit → manual release
```

**Dev Testing (use manual):**
```
dev branch → manual release → test in dev
```

## Integration with Other Workflows

### SQL Syntax Validation

Manual releases benefit from validation:
1. SQL validation workflow runs on push
2. If validation passes, manual release can be triggered
3. Ensures generated release has valid SQL

### Automatic Release Generation

Both workflows create releases with identical format:
- Same tag naming scheme
- Same artifact structure
- Same metadata format
- Interchangeable outputs

## Performance

- **Execution Time:** 2-3 minutes (similar to automatic workflow)
- **Scalability:** Handles thousands of SQL files
- **Storage:** Release artifacts stored indefinitely

## Related Workflows

- **Generate Release** (`generate-release.yml`) - Automatic release on merge
- **SQL Syntax Validation** (`validate-sql-syntax.yml`) - Pre-merge validation

## Examples

### Example 1: Dev Release (All Changes)
```
Environment: dev
Since Date: (blank)
Since Tag: (blank)
```
**Result:** Release with all SQL files in dev branch

### Example 2: QA Release (Last Week)
```
Environment: qa
Since Date: 2025-10-08
Since Tag: (blank)
```
**Result:** Release with QA changes from Oct 8 onward

### Example 3: Prod Hotfix (Since Last Release)
```
Environment: prod
Since Date: (blank)
Since Tag: prod-2025.10.15.1430
```
**Result:** Release with changes since last prod release

## Maintenance

### Updating Input Options

To add new input fields:
```yaml
inputs:
  your_new_input:
    description: 'Description here'
    required: false
    type: string
```

### Changing Default Environment

```yaml
inputs:
  environment:
    default: dev  # Change default here
```

## Version History

- **Initial Version (2025-10-15)**: Manual release with date/tag inputs
- **Added Multi-line Messages (2025-10-15)**: Support for multi-line commit messages
- **Added Semicolon Handling (2025-10-15)**: Automatic semicolon addition

---

**Last Updated:** 2025-10-15
**Workflow Version:** 1.0
**Status:** Production Ready

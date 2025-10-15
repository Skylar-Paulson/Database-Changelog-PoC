# Database Changelog Release Workflows

This directory contains GitHub Actions workflows for automatically generating database changelog releases from SQL migration files.

## Table of Contents

- [Workflows](#workflows)
  - [1. Automatic Release Generation](#1-automatic-release-generation-generate-releaseyml)
  - [2. Manual Release Generation](#2-manual-release-generation-manual-releaseyml)
- [Release Artifacts](#release-artifacts)
- [Tag Format](#tag-format)
- [Schema Folders](#schema-folders)
- [File Ordering](#file-ordering)
- [Security](#security)
- [Troubleshooting](#troubleshooting)
- [Example Workflow Run](#example-workflow-run)

## Workflows

### 1. Automatic Release Generation (`generate-release.yml`)

**Trigger**: Automatically runs when SQL files are pushed to `qa` or `prod` branches.

**What it does**:
1. Detects the environment from the branch name (`qa` or `prod`)
2. Finds the last release tag for that environment (e.g., `qa-2025.10.15.1430`)
3. Collects all SQL files added since the last release
4. Orders files chronologically by their Git commit timestamp
5. Generates a compiled SQL file with headers and metadata
6. Creates a ZIP archive with all individual SQL files (preserving folder structure)
7. Creates a GitHub Release with:
   - Tag: `{env}-{YYYY}.{MM}.{DD}.{HHMM}` (e.g., `qa-2025.10.15.1430`)
   - Release name: `{ENV} - {YYYY}.{MM}.{DD}.{HHMM}` (e.g., `QA - 2025.10.15.1430`)
   - Auto-generated release notes from commits
   - Compiled SQL file attachment
   - ZIP archive attachment

**Example compiled SQL format**:
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
-- File: auth/001_add_user_table.sql
-- Committed: 2025-10-15 10:15:30 -0400
-- Commit: a1b2c3d
-- Message: PROJ-1234: Add user table for authentication
-- ============================================
CREATE TABLE users (
  id INT PRIMARY KEY,
  name VARCHAR(100)
);

-- ============================================
-- Change 2 of 3
-- File: integrations/002_add_tokens.sql
-- Committed: 2025-10-15 11:20:15 -0400
-- Commit: e4f5g6h
-- Message: PROJ-1235: Add token storage table
-- ============================================
...
```

**Edge cases handled**:
- If no SQL files have changed since the last release, the workflow exits gracefully with a notice
- If no previous release tag exists, it compiles all SQL files from the repository start
- Excludes SQL files in `.github/` and `docs/` directories

---

### 2. Manual Release Generation (`manual-release.yml`)

**Trigger**: Manually triggered via GitHub Actions UI (Actions → Manual Database Changelog Release → Run workflow).

**Inputs**:
- **environment** (required): Choose from `dev`, `qa`, or `prod`
- **since_date** (optional): Compile changes since a specific date (format: `YYYY-MM-DD`)
- **since_tag** (optional): Compile changes since a specific Git tag

**What it does**:
Same as automatic workflow, but allows customization of:
1. Which environment to target (dev/qa/prod)
2. The starting point for collecting changes (date, tag, or last release)

**Input priority**:
1. If `since_tag` is provided → use that tag
2. Else if `since_date` is provided → use commit at or before that date
3. Else → use the last release tag for the specified environment
4. If no release tag exists → use repository start

**Example use cases**:
- Generate a `dev` release manually (since `dev` branch doesn't auto-trigger)
- Regenerate a release from a specific date: `since_date: 2025-10-01`
- Create a hotfix release from a specific tag: `since_tag: qa-2025.10.14.0900`

**Validation**:
- Ensures environment is one of: `dev`, `qa`, `prod`
- Validates date format if provided (YYYY-MM-DD)
- Verifies tag exists if provided
- Fails with error if no SQL files are found (unlike automatic workflow which silently skips)

---

## Release Artifacts

Each release includes two files:

1. **Compiled SQL file**: `database-changelog-{env}-{timestamp}.sql`
   - Single file containing all SQL changes
   - Includes headers with metadata for each change
   - Ready to execute in order

2. **ZIP archive**: `database-changelog-{env}-{timestamp}.zip`
   - Contains all individual SQL files
   - Preserves original folder structure (e.g., `auth/`, `integrations/`)
   - Useful for reviewing individual changes

---

## Tag Format

Release tags follow the format: `{env}-{YYYY}.{MM}.{DD}.{HHMM}`

Examples:
- `qa-2025.10.15.1430` → QA release on October 15, 2025 at 14:30 UTC
- `prod-2025.10.20.0900` → Production release on October 20, 2025 at 09:00 UTC
- `dev-2025.10.12.1615` → Dev release on October 12, 2025 at 16:15 UTC

The environment prefix is lowercase in tags, but uppercase in release names.

---

## Schema Folders

The workflows include SQL files from these folders:
- `auth/` - User security schema
- `application/` - Application schema
- `integrations/` - Credentials schema
- `tenants/` - Client-specific schemas
- Any other folders containing `.sql` files

Excluded:
- `.github/` - GitHub Actions configurations
- `docs/` - Documentation

---

## File Ordering

SQL files are ordered chronologically by the timestamp of the Git commit that **first added** the file. This ensures:
1. Dependencies are respected (files added earlier are applied first)
2. Consistent ordering across releases
3. Reproducible builds

The ordering uses: `git log --diff-filter=A --format=%at --all -- <file>`

---

## Security

All user inputs in the workflows are properly sanitized using environment variables to prevent command injection attacks. The workflows follow GitHub Actions security best practices:
- User inputs are always assigned to environment variables first
- No direct interpolation of user inputs in shell commands
- Input validation before processing

---

## Troubleshooting

**Problem**: Workflow doesn't trigger on push to `qa`/`prod`
- **Solution**: Ensure SQL files were actually changed (workflows only trigger when `**.sql` files are modified)

**Problem**: "No SQL files changed since last release"
- **Solution**: This is expected if no new SQL files were added since the last release. The workflow will skip creating a release.

**Problem**: Manual workflow fails with "No commits found before date"
- **Solution**: The specified date is before the repository was created. Use a more recent date.

**Problem**: Files appear in wrong order in compiled SQL
- **Solution**: The order is based on commit timestamps. If you need to reorder, you may need to adjust commit history (use with caution).

---

## Example Workflow Run

1. Developer pushes 3 new SQL files to `qa` branch:
   - `auth/001_add_user_table.sql`
   - `integrations/002_add_tokens.sql`
   - `auth/003_add_user_roles.sql`

2. Workflow automatically triggers

3. Workflow finds last release: `qa-2025.10.14.0900`

4. Workflow collects the 3 new SQL files and orders by commit time

5. Workflow generates:
   - `database-changelog-qa-2025.10.15.1430.sql` (compiled)
   - `database-changelog-qa-2025.10.15.1430.zip` (individual files)

6. GitHub Release created:
   - Tag: `qa-2025.10.15.1430`
   - Title: `QA - 2025.10.15.1430`
   - Body: Auto-generated from commits
   - Attachments: Both SQL and ZIP files

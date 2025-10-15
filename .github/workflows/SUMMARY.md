GitHub Actions Workflows Created for Database Changelog Release Generation
===========================================================================

## Table of Contents

- [FILES CREATED](#files-created)
- [WORKFLOW FEATURES](#workflow-features)
- [RELEASE FORMAT](#release-format)
- [ARTIFACTS](#artifacts)
- [SECURITY](#security)
- [USAGE](#usage)

FILES CREATED:
--------------
1. .github/workflows/generate-release.yml (7,169 bytes)
   - Automatic release generation on push to qa/prod branches
   
2. .github/workflows/manual-release.yml (8,928 bytes)
   - Manual release generation via workflow_dispatch
   
3. .github/workflows/README.md (6,600 bytes)
   - Complete documentation for both workflows

WORKFLOW FEATURES:
------------------
Both workflows include:
✓ Git-based file ordering by commit timestamp
✓ Environment detection (dev/qa/prod)
✓ Last release tag detection
✓ Compiled SQL file generation with headers
✓ ZIP archive creation with folder structure preservation
✓ GitHub Release creation with auto-generated notes
✓ Proper error handling and validation
✓ Security-hardened (no command injection vulnerabilities)

RELEASE FORMAT:
---------------
Tag:  {env}-{YYYY}.{MM}.{DD}.{HHMM}
Name: {ENV} - {YYYY}.{MM}.{DD}.{HHMM}

Example: qa-2025.10.15.1430 → "QA - 2025.10.15.1430"

ARTIFACTS:
----------
Each release includes:
1. database-changelog-{tag}.sql - Compiled SQL with headers
2. database-changelog-{tag}.zip - Individual SQL files

SECURITY:
---------
✓ All user inputs sanitized via environment variables
✓ No direct interpolation of untrusted data
✓ Input validation for dates and tags
✓ Follows GitHub Actions security best practices

USAGE:
------
Automatic: Push SQL files to qa or prod branches
Manual:    Actions → Manual Database Changelog Release → Run workflow
           - Choose environment (dev/qa/prod)
           - Optional: Specify since_date (YYYY-MM-DD)
           - Optional: Specify since_tag


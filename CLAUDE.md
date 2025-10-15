# Database Changelog Tracking System - CLAUDE.md

## Table of Contents

- [Project Overview](#project-overview)
- [The Problem Being Solved](#the-problem-being-solved)
- [Repository Structure](#repository-structure)
- [Branch Structure](#branch-structure)
- [Workflow Process](#workflow-process)
  - [Developer Workflow (Daily Use)](#developer-workflow-daily-use)
  - [Manager Workflow (Environment Promotion)](#manager-workflow-environment-promotion)
- [File Naming Conventions](#file-naming-conventions)
- [Release Artifacts (3 files per release)](#release-artifacts-3-files-per-release)
- [Release Naming Convention](#release-naming-convention)
- [GitHub Actions Workflows](#github-actions-workflows)
  - [1. Automatic Release Generation](#1-automatic-release-generation-generate-releaseyml)
  - [2. Manual Release Generation](#2-manual-release-generation-manual-releaseyml)
- [Key Technical Decisions](#key-technical-decisions)
  - [1. Git Commit Timestamps for Ordering](#1-git-commit-timestamps-for-ordering)
  - [2. No File Naming Validation](#2-no-file-naming-validation)
  - [3. Branch Protection](#3-branch-protection)
  - [4. Multi-Schema Support](#4-multi-schema-support)
- [Integration with Existing Systems](#integration-with-existing-systems)
  - [Release Note Generation](#release-note-generation)
  - [Jira Integration](#jira-integration)
- [Important Notes](#important-notes)
  - [✅ DO](#-do)
  - [❌ DON'T](#-dont)
- [Testing & Proof of Concept](#testing--proof-of-concept)
- [Success Criteria](#success-criteria)
- [Future Considerations (If PoC Approved)](#future-considerations-if-poc-approved)
- [Documentation Files](#documentation-files)
- [Databases at ExampleCorp](#databases-at-examplecorp)
- [Contact & Questions](#contact--questions)

## Project Overview

This is a **proof-of-concept** Git repository for tracking database changes across multiple environments (dev, qa, prod) at ExampleCorp.

**Purpose**: Solve the problem of missing database changes during environment promotions by treating database changes like code - tracked in Git with automated release generation.

## The Problem Being Solved

**Current State (Before This System):**
- Database changes tracked manually by single individual on their local machine
- Changes frequently missed during environment promotions (dev → qa → prod)
- Causes both obvious breaks and silent failures (e.g., missing enum table updates)
- Single point of failure (person sick/vacation = blocked deployments)
- Database changes not included in existing release notes system

**This Solution:**
- Git-based tracking (branch = environment state)
- Automated release file generation on merge
- Integrates with existing Jira/Git release note system
- Eliminates single point of failure
- Team-accessible, version-controlled, audit trail

## Repository Structure

```
database-changelog-test/
├── auth/              # User security database (auth) changes
├── application/   # Application database changes
├── integrations/          # Credentials database changes
├── tenants/       # Client schema changes (identical structure, different data)
├── .github/workflows/    # GitHub Actions workflows
│   ├── generate-release.yml    # Automatic release on merge to qa/prod
│   ├── manual-release.yml      # Manual release generation
│   └── README.md               # Workflow documentation
├── docs/
│   ├── Database-Changelog-Spec.md  # Full technical specification
│   └── USER-GUIDE.md               # How-to guide for developers/managers
├── README.md             # Project overview
└── CLAUDE.md             # This file - context for Claude Code
```

## Branch Structure

**Branch = Environment State**

- `dev` branch = dev database state
- `qa` branch = qa database state
- `prod` branch = prod database state

**Critical Rule**: Only commit SQL files to a branch AFTER applying them to the corresponding database environment.

**Branch Protection:**
- `qa`: Requires pull requests (no direct commits)
- `prod`: Requires pull requests (no direct commits)
- `dev`: Optional (currently allows direct commits)

## Workflow Process

### Developer Workflow (Daily Use)

1. Make database change in dev environment
2. Test and verify the change works
3. Save SQL to file in appropriate schema folder
4. Commit to `dev` branch with Jira reference (e.g., "PROJ-1234: Add MFA column")
5. Push to GitHub

### Manager Workflow (Environment Promotion)

**Promoting Dev → QA:**
1. Create pull request: `dev` → `qa`
2. Review and merge PR
3. GitHub Actions automatically:
   - Detects SQL files changed since last QA release
   - Orders changes by Git commit timestamp
   - Generates compiled SQL file
   - Creates ZIP with individual files
   - Creates GitHub Release with tag `qa-YYYY.MM.DD.HHMM`
   - Auto-generates release notes from commits
4. Manager downloads compiled SQL file from release
5. Manager executes SQL in QA database
6. QA branch now reflects QA database state

**Promoting QA → Prod:**
Same process, but `qa` → `prod` merge

## File Naming Conventions

**IMPORTANT**: File naming is **recommended but NOT enforced**

- Suggested format: `YYYYMMDD_HHMM_description.sql` or just `description.sql`
- Developers can name files however they want
- Git commit timestamps determine chronological ordering (not filename)
- Naming is for human readability/browsing only

**Why no strict enforcement?**
- Keep it developer-friendly and not cumbersome
- Git commit timestamps are reliable and persistent
- Avoid workflow overhead and complexity

## Release Artifacts (3 files per release)

Each GitHub Release contains:

1. **Compiled SQL File** (`database-changelog-{tag}.sql`)
   - Single file with all changes in chronological order
   - Includes metadata headers for each change
   - Ready to copy-paste into target database

2. **ZIP Archive** (`database-changelog-{tag}.zip`)
   - All individual SQL files
   - Preserves folder structure
   - For reference/audit purposes

3. **Release Notes**
   - Auto-generated from Git commit messages
   - Includes Jira issue references
   - Integrates with existing release note system

## Release Naming Convention

- **Tag format**: `{env}-{YYYY}.{MM}.{DD}.{HHMM}` (lowercase, e.g., `qa-2025.10.15.1430`)
- **Release name**: `{ENV} - {YYYY}.{MM}.{DD}.{HHMM}` (uppercase, e.g., `QA - 2025.10.15.1430`)
- 24-hour time format (no colons for Git tag compatibility)

## GitHub Actions Workflows

### 1. Automatic Release Generation (`generate-release.yml`)

**Triggers**: Push to `qa` or `prod` branches with SQL file changes

**Process**:
- Finds last release tag for environment
- Gets all SQL files added since last release using `git diff`
- Orders files by Git commit timestamp (reliable, persistent)
- Compiles into single SQL file with metadata
- Creates ZIP archive
- Creates GitHub Release with 3 assets

### 2. Manual Release Generation (`manual-release.yml`)

**Triggers**: Manual dispatch via GitHub Actions UI

**Inputs**:
- `environment`: Choose dev/qa/prod
- `since_date`: Optional (YYYY-MM-DD)
- `since_tag`: Optional (e.g., `qa-2025.10.01.0900`)

**Use Cases**:
- Emergency hotfixes
- Dev environment releases
- Generate release for specific date range

## Key Technical Decisions

### 1. Git Commit Timestamps for Ordering
- **Why**: Reliable, persistent across clones, handles dependencies
- **How**: `git log --diff-filter=A --format=%at -- <file> | head -1`
- **Not using**: Filesystem creation dates (reset on clone) or filenames

### 2. No File Naming Validation
- **Why**: Keep it developer-friendly, avoid cumbersome restrictions
- **Trade-off**: Inconsistent naming vs. low friction for developers
- **Decision**: Git handles ordering, naming is for humans only

### 3. Branch Protection
- **Why**: Prevent accidental changes to promoted environments
- **Implementation**: QA/Prod require PRs, Dev allows direct commits
- **Benefit**: Review process for promoted environments

### 4. Multi-Schema Support
- **Why**: ExampleCorp uses 4+ databases
- **Implementation**: Separate folders, single compiled release
- **Benefit**: One release file = all database changes across all schemas

## Integration with Existing Systems

### Release Note Generation
- ExampleCorp already has release note system using Jira + Git commits
- This repository enables database changes to be included automatically
- Database changes now tracked in Git like application code
- Unified release notes: code changes + database changes

### Jira Integration
- Include Jira issue references in commit messages (e.g., "PROJ-1234: ...")
- References appear in release notes automatically
- Links database changes to user stories/bugs

## Important Notes

### ✅ DO
- Apply database changes BEFORE committing to Git
- Include Jira references in commit messages
- Use descriptive commit messages
- Put files in correct schema folder
- Test changes locally before committing

### ❌ DON'T
- Commit SQL files that haven't been applied to corresponding database
- Force push to `qa` or `prod` branches
- Skip the PR process for `qa`/`prod` promotions
- Modify files after committing (create new change instead)

## Testing & Proof of Concept

This repository includes example SQL files for testing:
- `auth/` - MFA column, role permissions
- `application/` - Report templates, text indexes
- `integrations/` - Token expiration updates
- `tenants/` - Custom metrics column

**Testing Plan**:
1. Commit example files to `dev` branch
2. Merge `dev` → `qa` and verify release generation
3. Merge `qa` → `prod` and verify release generation
4. Verify chronological ordering across schemas
5. Demonstrate to stakeholders

## Success Criteria

For this PoC to be considered successful:
- ✅ Workflows execute without errors
- ✅ Release files contain all changes in correct order
- ✅ 3 artifacts generated per release
- ✅ Changes ordered chronologically by commit timestamp
- ✅ Multi-schema changes handled correctly
- ✅ Developer workflow is simple and not cumbersome
- ✅ Stakeholders approve the approach

## Future Considerations (If PoC Approved)

- Migrate from PoC to production use
- Add SQL syntax validation (optional)
- Add rollback SQL tracking
- Integrate with deployment automation
- Add schema-specific release files (if needed)
- Consider migration to Liquibase/Flyway (if needed)

## Documentation Files

- **README.md** - Project overview and quick start
- **docs/USER-GUIDE.md** - Practical how-to guide for daily use
- **docs/Database-Changelog-Spec.md** - Complete technical specification
- **.github/workflows/README.md** - Workflow documentation
- **CLAUDE.md** (this file) - Context for Claude Code sessions

## Databases at ExampleCorp

- **auth** - User security, authentication, authorization (user accounts, roles, permissions)
- **app_central** - Business logic, user data (companies, users, application tokens)
- **integrations** - Token definitions, data sources, metrics, dimensions
- **orchestrator** - Orchestrator-specific data
- **documents** - Document storage
- **Client schemas** - Multiple schemas with identical structure, different data per client

All use Aurora MySQL with Entity Framework Core + MySqlConnector.

## Contact & Questions

For questions about this PoC, see the USER-GUIDE.md or Database-Changelog-Spec.md documentation.

---

**Last Updated**: 2025-10-15
**Status**: Proof of Concept - Active Development
**Owner**: DBA Team Lead (ExampleCorp)

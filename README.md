# Database Changelog Tracking System

> [!NOTE]
> All SQL statements in this repository were generated specifically for example and testing purposes.

![Status: Proof of Concept](https://img.shields.io/badge/status-proof%20of%20concept-yellow)

**Git-based database change tracking with automated release generation for multi-environment deployments**

---

## Overview

This repository provides a **proof-of-concept** system for tracking database schema and data changes across multiple environments (dev, qa, prod) using Git as the source of truth. The system automates the generation of SQL migration scripts during environment promotions, ensuring database changes are never missed during code releases.

### The Problem

In a typical 3-environment setup (dev, qa, prod):
- Database changes made in development often **don't get propagated** to QA or production during code releases
- This causes **obvious breaks** (missing tables/columns that cause application crashes)
- And **silent failures** (missing enum updates that cause incorrect behavior without errors)
- No systematic way to track **what database changes exist in which environment**

### The Solution

This system uses **Git branches to track database state**:
- Each branch represents the current state of its corresponding database environment
- **dev branch** = dev database state
- **qa branch** = qa database state
- **prod branch** = prod database state

When you merge changes between environments (dev → qa → prod), GitHub Actions automatically:
1. Detects all NEW database changes since the last deployment
2. Compiles changes into a single SQL file in **chronological order**
3. Creates a **GitHub Release** with 3 assets:
   - Compiled SQL file (copy-paste ready for execution)
   - ZIP archive of individual SQL files (for reference/audit)
   - Auto-generated release notes (commit history for context)

**Key Benefits:**
- Never miss database changes during deployments
- Complete audit trail via Git history
- Chronological ordering preserves dependencies
- Copy-paste friendly SQL output
- Multi-database/multi-schema support

---

## Quick Start

### 1. Clone the Repository
```bash
git clone <repository-url>
cd database-changelog-test
```

### 2. Understand the Structure

The repository is organized by database schema:

```
database-changelog-test/
├── auth/              # User security database changes (auth, RBAC, audit)
├── application/   # Application database changes (business logic)
├── integrations/          # Credentials database changes (tokens, data sources)
├── tenants/       # Client schema changes (multi-tenant structures)
├── .github/workflows/    # GitHub Actions workflows
├── docs/                 # Documentation
│   ├── Database-Changelog-Spec.md    # Technical specification
│   └── USER-GUIDE.md                 # How to use this system
└── README.md             # This file
```

### 3. Read the Documentation

**New to this system?** Start with the [USER GUIDE](docs/USER-GUIDE.md)

**Want technical details?** See the [Technical Specification](docs/Database-Changelog-Spec.md)

### 4. Understand the Branches

- **dev branch** - Development database state (developers commit here after applying to dev DB)
- **qa branch** - QA database state (changes promoted from dev)
- **prod branch** - Production database state (changes promoted from qa)

**Critical Rule:** If a SQL file exists in a branch, that change has been applied to the corresponding database.

---

## Key Features

- **Automated Release Generation** - GitHub Actions creates releases on merge to qa/prod branches
- **Manual Release Generation** - On-demand release file generation for hotfixes or custom date ranges
- **Multi-Schema Support** - Track changes across multiple databases in a single repository
- **Chronological Ordering** - Changes applied in the order they were made (Git commit timestamp)
- **3 Release Assets** - Compiled SQL file, ZIP archive, and auto-generated release notes
- **Branch Protection** - Enforce PR reviews and status checks for qa/prod promotions
- **Duplicate Prevention** - Git merge behavior automatically prevents re-applying changes
- **Complete Audit Trail** - Git history provides full record of all changes and promotions

---

## Release Assets

Each GitHub Release includes 3 assets:

### 1. Compiled SQL File (Main Deployment File)
- **Filename**: `release-{environment}-{timestamp}.sql`
- **Purpose**: Copy-paste ready SQL for execution
- **Contents**: All database changes in chronological order with metadata
- **Use**: Download this file, review it, and execute in target database(s)

Example:
```sql
-- ============================================================
-- Database Changelog Release: QA
-- Generated: 2025-10-15 14:30:00
-- Branch: qa
-- Total Changes: 3
-- ============================================================

-- ============================================================
-- Change 1/3
-- Schema: auth
-- File: auth/add_user_role_column.sql
-- Commit: a1b2c3d4
-- Message: Add user role column for RBAC support
-- Author: john.doe@example.com
-- Date: 2025-10-15 12:00:00
-- ============================================================

ALTER TABLE users ADD COLUMN default_role_id INT NULL;
-- ... more changes ...
```

### 2. ZIP Archive (Reference/Audit)
- **Filename**: `release-{environment}-{timestamp}-individual-files.zip`
- **Purpose**: View individual SQL files as originally written
- **Contents**: All SQL files in original folder structure (auth/, integrations/, etc.)
- **Use**: Download for detailed inspection, audit trail, or debugging

### 3. Release Notes (Context)
- **Auto-generated** by GitHub from commit messages
- **Contents**: List of commits included in this release with authors, dates, messages
- **Use**: Read to understand what changed and why

**Release Naming Convention:**
- Format: `{ENVIRONMENT} - {YEAR}.{MONTH}.{DAY}.{HHMM}`
- Examples: `QA - 2025.10.15.1439`, `PROD - 2025.10.16.0930`

---

## Repository Structure

| Folder | Database | Purpose |
|--------|----------|---------|
| `auth/` | User security database | Authentication (Cognito), authorization (RBAC), audit trails, user management |
| `application/` | Application database | Business logic, user data, companies, NLP features, application data |
| `integrations/` | Credentials database | Token definitions, data sources, metrics, dimensions, API integrations |
| `tenants/` | Client databases | Client-specific schema changes that apply to multiple client databases |
| `.github/workflows/` | N/A | GitHub Actions workflows for automated and manual release generation |
| `docs/` | N/A | Documentation (specification, user guide) |

---

## Workflows

### 1. Generate Release File (Automatic)
- **Trigger**: Merge to `qa` or `prod` branches
- **Purpose**: Automatically generate SQL release files for environment promotion
- **Output**: GitHub Release with 3 assets (compiled SQL, ZIP, release notes)
- **Typical run time**: < 2 minutes

### 2. Manual Release Generation
- **Trigger**: Manual workflow dispatch with date range parameters
- **Purpose**: Generate release files for hotfixes or custom deployments
- **Use cases**: Emergency fixes, partial deployments, historical release generation
- **How to use**: Actions tab → Manual Release Generation → Run workflow → Specify branch and date range

### 3. SQL Naming Validation (Optional)
- **Trigger**: Pull request creation/update
- **Purpose**: Enforce SQL file naming conventions (if enabled)
- **Status**: Optional - check with your team if this is enabled

---

## Branches

### Environment-Branch Mapping

The system uses **Git branches to represent database states**:

| Branch | Environment | Purpose |
|--------|-------------|---------|
| `dev` | Development | Developers commit here AFTER applying changes to dev database |
| `qa` | QA/Staging | Changes promoted from dev via pull request |
| `prod` | Production | Changes promoted from qa via pull request |

### Branch Protection Rules

**qa and prod branches are protected:**
- Require pull requests before merging (no direct commits)
- Require status checks to pass (naming validation, if enabled)
- Require branches to be up to date before merging
- No force pushes allowed
- No branch deletion allowed

**dev branch:**
- Protection rules TBD based on team preference (direct commits vs PRs)

---

## How It Works

### Developer Workflow (Making a Change)

1. **Apply change to dev database** (execute SQL directly)
2. **Test the change** in dev environment
3. **Create SQL file** with the change in appropriate schema folder
4. **Commit to dev branch** with descriptive message
5. **Push to remote** - change is now tracked in Git

### Promotion Workflow (Dev → QA → Prod)

1. **Manager creates pull request** (e.g., dev → qa)
2. **Team reviews PR** (sees all SQL changes since last promotion)
3. **Merge PR** to target branch
4. **GitHub Actions triggers automatically** on merge
5. **Workflow generates release** with all NEW changes
6. **GitHub Release created** with 3 assets (compiled SQL, ZIP, release notes)
7. **Manager downloads compiled SQL** from release
8. **Manager executes SQL** in target database(s)
9. **Database is now up to date** with promoted changes

**Key Concept:** Git diff automatically identifies what needs to be applied - changes already in the target branch are excluded.

---

## Status: Proof of Concept

This repository serves as a **proof-of-concept** to:
- Demonstrate the feasibility of Git-based database changelog tracking
- Provide a working prototype to validate workflows and approach
- Show stakeholders how the system works through realistic examples
- Test automated and manual release file generation processes
- Validate multi-schema change tracking across environments

### What's Included

- Example SQL files across all schema folders for testing and demonstration
- Fully functional GitHub Actions workflows (automated and manual)
- Complete documentation (spec, user guide)
- Branch protection setup (ready to enable)
- Release generation with 3 assets

### Success Criteria

The PoC is successful if:
- Automated workflow generates release files on qa/prod merges
- Release files contain all changes in correct chronological order
- Changes from all schema folders are included and clearly labeled
- Duplicate prevention works (already-promoted changes excluded)
- Manual workflow generates targeted release files for hotfixes
- Stakeholders understand and approve the approach
- Team agrees the workflow is simple enough to adopt

### Next Steps (If Approved)

If the PoC is approved for production use:
1. Remove example SQL files
2. Update documentation with finalized guidelines
3. Enable branch protection rules for qa/prod branches
4. Train team on workflow and best practices
5. Pilot with small group of developers
6. Monitor and iterate based on feedback
7. Full team rollout after successful pilot

---

## Documentation

### For Users

**[USER GUIDE](docs/USER-GUIDE.md)** - Comprehensive guide for developers and release managers
- Quick start guide
- Developer workflow (making changes)
- Manager workflow (promoting changes)
- Release file generation and execution
- Schema folder explanations
- Common workflows (hotfixes, rollbacks, multi-developer scenarios)
- FAQ and troubleshooting
- GitHub Actions workflow details

### For Architects/Implementers

**[Technical Specification](docs/Database-Changelog-Spec.md)** - Full architectural and technical details
- Goals and scope
- Core concepts and terminology
- Architecture and design decisions
- Git workflow and branching strategy
- Process flows and error handling
- Technical requirements
- Testing strategy and PoC demonstration plan
- Open questions and decisions

---

## Usage

### For Developers

See the [Developer Workflow](docs/USER-GUIDE.md#for-developers) section in the User Guide.

**Quick summary:**
1. Apply database change to dev database
2. Create SQL file in appropriate schema folder (e.g., `auth/20251015_1200_add_column.sql`)
3. Commit to dev branch
4. Push to remote

### For Managers/Release Coordinators

See the [Manager Workflow](docs/USER-GUIDE.md#for-managersrelease-coordinators) section in the User Guide.

**Quick summary:**
1. Create pull request (dev → qa or qa → prod)
2. Review and merge PR
3. Download compiled SQL from GitHub Release
4. Execute in target database(s)
5. Verify changes applied correctly

---

## Questions or Issues

**Questions?**
- Check the [User Guide](docs/USER-GUIDE.md) first
- Check the [Technical Specification](docs/Database-Changelog-Spec.md) for detailed information
- Ask your team lead or database administrator
- Reach out in team Slack channel

**Found a bug or have a suggestion?**
- Open an issue in this repository
- Include details: what you did, what happened, what you expected
- Include relevant SQL files and error messages

---

## Contributing

This is a proof-of-concept system. Feedback and suggestions are welcome!

To contribute:
1. Review the [Technical Specification](docs/Database-Changelog-Spec.md) for design decisions and open questions
2. Open an issue to discuss your proposed changes
3. Follow the workflows described in the [User Guide](docs/USER-GUIDE.md)
4. Submit a pull request with your changes

---

## License

[Specify license here]

---

## Summary

**Key Takeaways:**
1. **Branch = Database State** - If a SQL file exists in a branch, that change is in the database
2. **Apply Database First, Commit Second** - Always apply to database before committing to Git
3. **GitHub Releases with 3 Assets** - Compiled SQL (main), ZIP (reference), release notes (context)
4. **Automatic Release Generation** - GitHub Actions creates releases on merge to qa/prod
5. **Chronological Ordering** - Git commit timestamps determine order, not filenames
6. **Multi-Schema Support** - Track changes across multiple databases in one repository
7. **Duplicate Prevention** - Git merge behavior prevents re-applying changes
8. **Manual Hotfixes** - On-demand release generation for emergency situations

**This system solves the critical problem of database changes not being properly propagated during code releases, providing systematic tracking, automated release generation, and complete audit trails through Git.**

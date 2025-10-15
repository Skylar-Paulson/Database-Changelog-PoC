# Project Specification

## Overview

### Purpose
Database changelog tracking system for managing database changes across multiple environments (dev, qa, prod). The system tracks all database schema and data changes in Git and automates the generation of SQL migration scripts during environment promotions.

**This repository serves as a proof-of-concept/example implementation** to:
- Demonstrate the feasibility of Git-based database changelog tracking
- Provide a working prototype to validate workflows and approach
- Show coworkers how the system works through realistic examples
- Test the automated and manual release file generation processes
- Validate multi-schema change tracking across environments

### Goals
This project solves the critical problem of database changes not being properly propagated during code releases:

1. **Never miss database changes** - Systematic tracking ensures all database changes are captured and promoted to target environments
2. **Maintain complete history** - Git-based tracking provides full audit trail of all database changes
3. **Environment visibility** - Clear understanding of what database changes exist in which environment
4. **Easy execution** - Copy-paste friendly SQL output for straightforward database updates
5. **Correct ordering** - Changes applied in chronological order to preserve dependencies
6. **Provide working proof-of-concept** - Demonstrate viability to stakeholders through realistic testing examples
7. **Integrate with existing release note generation system** - Database changes tracked in Git like application code, enabling unified release notes
8. **Eliminate single point of failure** - Central repository accessible to entire team, no dependency on individual's local machine
9. **Enable team collaboration** - Multiple developers can make database changes with clear visibility and shared responsibility

**Core Problem:**

*Current Database Change Tracking Approach:*
- Company relies on a single individual to maintain a local list of database changes
- This list exists only on that person's local computer (not in version control)
- Creates critical single point of failure:
  - Person gets sick → no access to change list → deployments blocked
  - Person on vacation → no one knows what database changes were made
  - Person leaves company → entire change history lost
  - Extra manual work burden on that individual
- No integration with existing release note generation system
- Error-prone process (easy to forget to update the list)
- Not accessible to team members

*Technical Problems:*
- 3 database environments: dev, qa, prod
- Database changes made in one environment (e.g., dev) frequently don't get propagated to other environments (qa, prod) during code releases
- This causes both obvious breaks (missing tables/columns) and silent failures (e.g., missing enum table updates that cause incorrect application behavior)
- No systematic tracking of what database changes exist in which environment
- Database changes invisible to existing release note generation system (which uses Git/Jira for application code)

### Scope

**In Scope:**
- Git repository for tracking SQL change files
- Automated GitHub Actions workflow for generating release files on merge to qa/prod branches
- Manual workflow for generating release files from specific date ranges
- Compilation of changes in chronological order
- Single SQL file output for easy copy-paste execution
- **Example SQL files across all schema folders for testing and demonstration purposes**
- **Testing the complete workflow from dev → qa → prod with realistic examples**

**Out of Scope:**
- Automatic database execution (changes are compiled but not auto-applied)
- Database migration frameworks (Flyway, Liquibase, etc.) - this is a simpler solution
- Schema validation or comparison tools
- Database backup/restore functionality
- Multi-tenancy support (assumes single database per environment)

---

## Integration with Existing Systems

### Existing Release Note Generation System

The company already has a release note generation system that:
- Uses Jira issues and Git commits/PR history from application repositories
- Generates comprehensive release notes for environment promotions (dev → qa → prod)
- Provides visibility into what code changes are being deployed
- **Currently DOES NOT include database changes** (because they're not tracked in Git)

**The Problem:** Release notes are incomplete - they show application code changes but miss database changes entirely.

### How This Repository Integrates

By tracking database changes in Git (just like application code), this repository enables:

1. **Unified Release Notes** - Database changes can now be included alongside application code changes
   - Existing release note generator treats this as just another Git repository
   - Same Jira issue references work (e.g., "PROJ-123: Add user role column")
   - Database changes show up in release notes automatically

2. **No Special Handling Required** - Database changelog repository is a standard Git repo
   - No changes needed to existing release note generation system
   - Same workflows, same tooling, same processes
   - Database changes are "first-class citizens" in release process

3. **Complete Deployment Picture** - Release notes now show:
   - Application code changes (from code repositories)
   - Database schema changes (from this repository)
   - Jira issues referenced in both
   - Full context for deployment planning

### Example: Unified Release Notes

**Before (Current System):**
```
Release Notes - QA Deployment - 2025.10.15

Application Changes:
- PROJ-123: Implement user role management
- PROJ-124: Add company settings page
- PROJ-125: Fix authentication bug

Database Changes:
- (Missing - not tracked in Git)
```

**After (With This Repository):**
```
Release Notes - QA Deployment - 2025.10.15

Application Changes:
- PROJ-123: Implement user role management
- PROJ-124: Add company settings page
- PROJ-125: Fix authentication bug

Database Changes:
- PROJ-123: Add role columns to users table (auth)
- PROJ-123: Insert default system roles (auth)
- PROJ-124: Add company settings table (application)
- PROJ-125: Update token visibility for public tokens (integrations)

Note: Database changes automatically linked to Jira issues via commit messages
```

### Benefits of Integration

**For Release Management:**
- Complete visibility into all changes (code + database)
- Easier deployment planning and coordination
- Reduced risk of missed database changes
- Jira issue tracking across all changes

**For Team Members:**
- Single source of truth for what's being deployed
- Clear connection between code changes and required database changes
- Better understanding of deployment scope
- Improved communication across development and operations

**For Compliance/Audit:**
- Complete audit trail of all changes (code and database)
- Git history provides timestamp, author, and reason for each change
- Release notes document exactly what was deployed when
- No gaps in change tracking

---

## Comparison: Current vs Proposed Approach

This section highlights the operational improvements this repository provides over the current manual tracking approach.

| Aspect | Current Approach (Local List) | Proposed Approach (Git Repository) |
|--------|-------------------------------|-----------------------------------|
| **Accessibility** | Single person's local computer only | Central repository accessible to entire team |
| **Bus Factor** | Critical single point of failure | Team can continue even if individual unavailable |
| **Manual Effort** | Individual manually maintains change list | Git automatically tracks all changes |
| **Integration** | No integration with release notes | Automatic integration with existing release note system |
| **Audit Trail** | No version control or history | Complete Git history with timestamps, authors, reasons |
| **Team Collaboration** | Single person responsible | Multiple developers can contribute and review |
| **Risk of Loss** | Change history lost if computer fails or person leaves | Permanent record in version control (backed up) |
| **Deployment Blockers** | Person on vacation = deployments blocked | Deployments can proceed regardless of individual availability |
| **Error Prone** | Easy to forget to update list | Commit after database change = automatic tracking |
| **Release Generation** | Manual compilation and selection | Automated generation via GitHub Actions |
| **Visibility** | List may not reflect actual database state | Branch = database state (clear mapping) |
| **Conflict Resolution** | Manual coordination between developers | Git merge process handles conflicts |
| **Knowledge Sharing** | Knowledge siloed with one person | Transparent process visible to all team members |

### Real-World Scenarios

**Scenario 1: Person on Vacation**

*Current Approach:*
- QA deployment needed urgently
- Person with change list is on vacation
- No one knows what database changes were made in dev
- Deployment blocked until person returns
- Rush to contact person during vacation (poor work-life balance)

*Proposed Approach:*
- QA deployment needed urgently
- Team member creates PR: dev → qa branch
- GitHub Actions automatically generates release file with ALL changes since last QA deployment
- Release manager downloads compiled SQL and executes in QA
- Deployment proceeds without interruption

**Scenario 2: Person Leaves Company**

*Current Approach:*
- Person maintaining change list leaves company
- Change history exists only on their local computer
- No handoff process (wasn't tracked in version control)
- Team has no record of what database changes exist where
- Must manually audit databases to reconstruct state

*Proposed Approach:*
- Person leaves company
- All database changes tracked in Git repository
- Complete history preserved with commit messages, timestamps, authors
- New team member can immediately see what changes exist in each environment
- `git diff qa..prod` shows exactly what needs to be promoted
- No knowledge loss or disruption

**Scenario 3: Person Gets Sick**

*Current Approach:*
- Person maintaining change list out sick for a week
- Critical database change needed in production
- No access to change list
- Team doesn't know what changes are pending or already applied
- Production deployment delayed or done blindly (risky)

*Proposed Approach:*
- Person out sick for a week
- Team member checks Git branches to see database state
- Creates hotfix SQL file, commits to hotfix branch
- Triggers manual GitHub Actions workflow for targeted release
- Executes hotfix in production safely
- No dependency on unavailable individual

**Scenario 4: Multiple Developers Making Changes**

*Current Approach:*
- Developer A makes database change in dev
- Developer A forgets to tell person maintaining list
- Developer B makes conflicting database change
- Person maintaining list doesn't know about conflicts
- QA deployment includes conflicting changes
- Database breaks, time wasted debugging

*Proposed Approach:*
- Developer A makes database change, commits SQL file to dev branch
- Developer B makes database change, commits SQL file to dev branch
- PR review from dev → qa shows BOTH changes
- Team reviews SQL files together, spots conflict
- Developers resolve conflict before QA deployment
- Clean promotion with no surprises

### Key Improvements Summary

1. **Eliminates Single Point of Failure**
   - Current: One person, one computer, one failure point
   - Proposed: Central repository, entire team, redundant access

2. **Integrates with Existing Systems**
   - Current: Database changes invisible to release note generation
   - Proposed: Database changes included automatically in release notes

3. **Reduces Manual Effort**
   - Current: Manual list maintenance, manual compilation, manual selection
   - Proposed: Git tracks automatically, GitHub Actions generates automatically

4. **Improves Reliability**
   - Current: Easy to forget updates, no version control, error-prone
   - Proposed: Commit = tracking, Git history = audit trail, automated processes

5. **Enables Team Collaboration**
   - Current: Single owner, siloed knowledge, no collaboration
   - Proposed: Shared responsibility, transparent process, code review for database changes

6. **Prevents Deployment Blockers**
   - Current: Person unavailable = deployments blocked
   - Proposed: Team can continue regardless of individual availability

---

## Key Concepts

### Core Terminology

- **Change File**: A SQL file containing a single database change (schema or data modification)
- **Release File**: A compiled SQL file containing all changes since the last release, generated automatically during environment promotion
- **Environment Promotion**: The process of moving changes from one environment to the next (dev → qa → prod)
- **Chronological Order**: Changes are applied in the order they were originally created/committed, not alphabetical or arbitrary order
- **Silent Failure**: Database changes that don't cause obvious errors but result in incorrect application behavior (e.g., missing enum values)
- **Branch-Environment Mapping**: Each Git branch represents the current state of its corresponding database environment (dev branch = dev database state, qa branch = qa database state, prod branch = prod database state)

### Assumptions

- Git is the single source of truth for all database changes
- Developers commit SQL change files to the repository when making database changes
- **Branch state tracks database state**: Developers ONLY commit to a branch AFTER applying the change to the corresponding database
- Changes are made in dev environment first, then promoted to qa, then prod
- Each environment has a corresponding Git branch (dev, qa, prod)
- **Branch = environment mapping**: dev branch represents dev database state, qa branch represents qa database state, prod branch represents prod database state
- Database changes are forward-only (no automatic rollbacks)
- Manual execution of generated SQL is acceptable (no automatic application required)
- SQL files are written for a specific database system (likely MySQL for ProductName projects)
- **If a commit exists in a branch, the change has been applied to that environment's database**

---

## Functionality

### Core Features

1. **SQL Change File Tracking**
   - Developers create SQL files for each database change
   - Files are committed to the Git repository
   - Git history provides complete audit trail
   - Changes are tracked with timestamps for chronological ordering
   - Expected behavior: Every database change has a corresponding committed SQL file

2. **Automated Release File Generation (GitHub Actions)**
   - Triggered automatically on merge to qa or prod branches
   - Scans ALL schema folders (auth, application, integrations, tenants) for changes since last release
   - Identifies all SQL changes across all schemas since the last release/merge
   - Compiles changes into a single SQL file in chronological order (order they were originally made)
   - **Generates 3 release assets as GitHub Release:**
     1. **Compiled SQL File** - Single file with all changes, copy-paste ready for execution
     2. **ZIP Archive** - Contains all individual SQL files in original folder structure for reference/audit
     3. **Release Notes** - Auto-generated from commit messages using GitHub's release note generation
   - **Release Naming Convention**: `{ENVIRONMENT} - {YEAR}.{MONTH}.{DAY}.{HHMM}` (e.g., `QA - 2025.10.15.1439`)
   - Output is copy-paste ready - can be executed directly against target database
   - Expected behavior: Every merge to qa/prod creates a GitHub Release with all assets

3. **Manual Release File Generation**
   - Manual GitHub Actions workflow for custom date ranges
   - Allows generating release files outside of standard promotion flow
   - Useful for partial deployments or hotfixes
   - User specifies start/end dates or commits
   - Expected behavior: On-demand generation of SQL release files for specified time periods

4. **Change Compilation**
   - Aggregates multiple SQL change files across ALL schema folders into single output
   - **Maintains chronological order based on Git commit timestamps** (not filename or filesystem dates)
   - Orders changes by when they were committed to Git (the order they were originally made)
   - Preserves original change order to handle dependencies correctly
   - Includes metadata (commit hash, commit message, commit timestamp, author, date, schema folder)
   - Copy-paste friendly format
   - Expected behavior: Output is a single SQL file that can be executed directly against target database, with changes in Git commit order

### User Stories / Use Cases

**Use Case 1: Developer Makes Database Change in Dev**
- **Actor**: Backend developer
- **Goal**: Add a new column to a table in dev database and ensure it's tracked for promotion
- **Steps**:
  1. Developer makes database change directly in dev database (e.g., auth database)
  2. Developer creates SQL file containing the change (e.g., `ADD COLUMN new_field VARCHAR(100)`)
  3. Developer commits SQL file to appropriate schema folder (e.g., `auth/20251015_1200_add_new_field.sql` or `auth/add_new_field.sql`) on dev branch with descriptive commit message
  4. SQL file is now tracked in Git with commit timestamp
- **Expected Outcome**: Database change is recorded in correct schema folder and ready for promotion to qa/prod
- **Note**: Filename can follow any convention - Git commit timestamp will determine order in release files

**Use Case 2: Promoting Changes from Dev to QA**
- **Actor**: DevOps engineer or release manager
- **Goal**: Deploy all dev database changes to qa environment
- **Steps**:
  1. Code and database changes are merged from dev branch to qa branch
  2. GitHub Actions workflow automatically triggers on merge
  3. Workflow scans all schema folders (auth, application, integrations, tenants) for changes since last qa deployment
  4. Workflow identifies all SQL changes across all schemas since last qa deployment
  5. Workflow generates release file with all changes in chronological order (order they were originally made)
  6. Engineer downloads release file from GitHub Actions artifacts
  7. Engineer reviews release file (contains metadata indicating which schema each change targets)
  8. Engineer copies and pastes SQL into qa databases (executing changes for each schema)
- **Expected Outcome**: All database changes from dev across all schemas are successfully applied to qa in correct order

**Use Case 3: Emergency Hotfix Database Change**
- **Actor**: Senior developer
- **Goal**: Apply a critical database fix to prod without full deployment
- **Steps**:
  1. Developer creates SQL file for hotfix
  2. Developer commits to hotfix branch
  3. Developer manually triggers GitHub Actions workflow specifying date range
  4. Workflow generates release file containing only the hotfix change
  5. Developer reviews and executes SQL in prod
- **Expected Outcome**: Single critical change is safely applied to prod without deploying all pending changes

---

## Architecture / Design

### High-Level Architecture

```
Developer → Git Repository (Schema Folders) → GitHub Actions → GitHub Release → Database
                                                     ↓              ↓
                                              3 Release Assets:  Manager
                                              1. Compiled SQL    downloads
                                              2. ZIP of files    and
                                              3. Release notes   executes
```

**Flow:**
1. Developer commits SQL change files to appropriate schema folder
2. On merge to qa/prod, GitHub Actions workflow triggers
3. Workflow scans all schema folders for changes since last release
4. Compiles changes chronologically into single SQL file
5. Creates GitHub Release with:
   - Tag: `{environment}-{timestamp}` (e.g., `qa-2025.10.15.1439`)
   - Title: `{ENVIRONMENT} - {YEAR}.{MONTH}.{DAY}.{HHMM}` (e.g., `QA - 2025.10.15.1439`)
   - Assets: Compiled SQL file, ZIP of individual files, auto-generated release notes
6. Engineer downloads compiled SQL from release and executes against target database

### Branching Model

```
                 dev branch                    qa branch                    prod branch
                 (dev database)                (qa database)                (prod database)
                      │                              │                             │
                      │ Developer                    │                             │
                      │ commits after                │                             │
                      │ applying to dev              │                             │
                      ↓                              │                             │
              [SQL Change File]                      │                             │
                      │                              │                             │
                      │ PR: dev → qa                 │                             │
                      ├─────────────────────────────→│                             │
                      │                              │                             │
                      │           Merge triggers     │                             │
                      │           GitHub Actions     │                             │
                      │                 ↓            │                             │
                      │          [Release File]      │                             │
                      │                 ↓            │                             │
                      │       Manager executes       │                             │
                      │       in qa database         │                             │
                      │                              ↓                             │
                      │                    [QA Database Updated]                   │
                      │                              │                             │
                      │                              │ PR: qa → prod               │
                      │                              ├────────────────────────────→│
                      │                              │                             │
                      │                              │      Merge triggers         │
                      │                              │      GitHub Actions         │
                      │                              │            ↓                │
                      │                              │     [GitHub Release]        │
                      │                              │     - Compiled SQL          │
                      │                              │     - ZIP of files          │
                      │                              │     - Release notes         │
                      │                              │            ↓                │
                      │                              │  Manager downloads          │
                      │                              │  and executes in prod DB    │
                      │                              │                             ↓
                      │                              │                  [Prod Database Updated]
```

**Branch-Environment Mapping:**
- **dev branch** = Current state of dev database
- **qa branch** = Current state of qa database
- **prod branch** = Current state of prod database

**Key Principle:** If a SQL change file exists in a branch, that change has been applied to the corresponding database environment.

### Repository Structure

The repository organizes SQL changes by database schema using folders:

```
database-changelog-test/
├── auth/
│   ├── 20251015_1200_add_user_role_column.sql
│   ├── add_default_roles.sql
│   └── ...
├── application/
│   ├── 20251015_1330_create_nlp_table.sql
│   ├── company_index.sql
│   └── ...
├── integrations/
│   ├── 20251015_1415_add_token_attribute.sql
│   ├── 20251017_update_datasource_metrics.sql
│   └── ...
├── tenants/
│   ├── add_campaign_field.sql
│   ├── 20251018_1510_alter_keyword_table.sql
│   └── ...
├── .github/
│   └── workflows/
│       ├── generate-release.yml
│       ├── manual-release.yml
│       └── validate-naming.yml
└── docs/
    └── SPEC.md
```

**Note on File Naming:**
- Example shows mix of naming styles to illustrate flexibility
- Some files use timestamp prefix (`20251015_1200_...`), others don't
- Functional ordering is determined by Git commit timestamp, not filename
- Timestamp in filename is recommended for human readability but not required

**Schema Folder Organization:**
- **auth/** - User security database changes (authentication, authorization, audit)
- **application/** - Application database changes (business logic, user data)
- **integrations/** - Credentials database changes (token definitions, data sources, metrics)
- **tenants/** - Client schema changes (multiple client schemas with identical structure but different data)

This structure addresses multi-database tracking by separating changes per schema while maintaining a single repository for coordination.

### Branch Protection & CI/CD

#### Branch Protection Rules

**Protection Strategy:**

The repository uses branch protection rules to enforce code quality and prevent accidental direct commits to promoted environments:

- **`prod` branch**: **REQUIRED** - Pull requests mandatory, no direct commits allowed
  - Rationale: Production is the critical environment - all changes must be reviewed
  - Requires: At least one approval, passing status checks
  - Prevents: Direct pushes, force pushes, branch deletion

- **`qa` branch**: **REQUIRED** - Pull requests mandatory, no direct commits allowed
  - Rationale: QA is a promoted environment where changes are tested before production
  - Requires: Passing status checks (validation workflows)
  - Prevents: Direct pushes, force pushes, branch deletion

- **`dev` branch**: **OPTIONAL** - Direct commits allowed (TBD based on team preference)
  - Rationale: Development environment where developers actively work
  - Options:
    - Allow direct commits for faster development workflow
    - Require PRs for better code review and change tracking
  - Decision factors: Team size, change frequency, review requirements

**Required Status Checks:**

All pull requests to `qa` and `prod` branches must pass:
- SQL file naming validation (if enforcement is enabled - see below)
- Any other CI/CD checks added in the future

**Benefits:**
- Audit trail: All changes to qa/prod have associated pull requests
- Review opportunity: Team can review database changes before promotion
- Prevents accidents: No accidental direct commits to production
- Clear workflow: Enforces dev → qa → prod promotion path

#### CI/CD Workflows

**Automated Workflows:**

1. **Release File Generation** (`generate-release.yml`)
   - Trigger: Merge to `qa` or `prod` branches
   - Purpose: Automatically generate SQL release files for environment promotion
   - Process: Scans all schema folders, compiles changes chronologically, generates artifact

2. **Manual Release Generation** (`manual-release.yml`)
   - Trigger: Manual workflow dispatch with date range parameters
   - Purpose: Generate release files for hotfixes or custom deployments
   - Process: Filters changes by date range, compiles into release file

3. **SQL Naming Validation** (`validate-naming.yml`) - OPTIONAL
   - Trigger: Pull request creation/update (to any branch)
   - Purpose: Enforce SQL file naming conventions (if enabled)
   - Process: Validates SQL files match expected naming pattern
   - Status: Blocks PR merge if validation fails

#### SQL File Naming Enforcement

**Context:** While Git commit timestamps determine functional ordering, enforcing a naming convention can improve human readability and repository organization.

**Recommended Convention:**
```
YYYYMMDD_HHMM_description.sql
```
Example: `20251015_1430_add_user_role_column.sql`

**Enforcement Options:**

**Option 1: No Enforcement (Current Default)**
- Pros:
  - Maximum developer flexibility
  - No workflow overhead
  - Developers can choose descriptive names
  - Functional ordering by Git commit timestamp is reliable regardless of naming
- Cons:
  - Inconsistent naming across files
  - Harder to visually scan chronology in file browser
  - Potential confusion for developers used to timestamp-based systems
- When to use: Small teams, low change frequency, trust in Git workflow

**Option 2: Validation Workflow (Recommended if Enforcing)**
- Implementation: GitHub Actions workflow validates file naming on PR creation
- Process:
  1. Workflow triggers on `pull_request` events (opened, synchronize, reopened)
  2. Gets list of changed files from PR
  3. Filters for SQL files in schema folders (`auth/`, `application/`, etc.)
  4. Validates each SQL file matches naming pattern: `YYYYMMDD_HHMM_*.sql`
  5. Excludes non-SQL files and files in `.github/`, `docs/`, etc.
  6. Fails PR status check if non-compliant files found
  7. Provides suggested names in workflow output
- Pros:
  - Enforces consistency without auto-modifying files
  - Developers retain control (must manually rename)
  - No Git history pollution from auto-renames
  - Clean, predictable, no conflicts
  - Can be configured as warning-only or blocking
- Cons:
  - Requires manual fix by developer if naming is wrong
  - Adds friction to PR workflow
  - Workflow maintenance overhead
- When to use: Larger teams, need for consistency, repository standardization

**Option 3: Auto-Rename Workflow (NOT RECOMMENDED)**
- Implementation: Workflow automatically renames files to match convention
- Process: Detects non-compliant files, renames them, commits changes
- Pros:
  - Automatic enforcement, no developer action needed
  - Guaranteed consistency
- Cons:
  - **MAJOR RISK**: Concurrent commits could cause conflicts and race conditions
  - Confusing Git history with automated rename commits
  - Could cause merge conflicts if developer pushes while workflow runs
  - Removes developer's intentional naming choices
  - Complex to implement correctly
  - Timing issues and edge cases
- **Recommendation**: Do not use - risks outweigh benefits

**Decision Factors:**

Consider enforcing naming conventions if:
- Team is larger (5+ developers)
- Change frequency is high (multiple changes per day)
- Repository is used by less Git-experienced developers
- Visual chronology scanning is important for your workflow
- Consistency is a priority for your organization

Consider flexible naming if:
- Team is small (1-4 developers)
- Change frequency is low
- Developers are Git-proficient
- Descriptive names are more important than timestamp prefixes
- Git commit timestamps are sufficient for ordering

**Current Recommendation:**
- Start with **no enforcement** (Option 1)
- Add **validation workflow** (Option 2) if consistency issues arise
- Make validation **blocking** for qa/prod branches, **warning-only** for dev branch
- Never use auto-rename workflow (Option 3)

### Components
_Break down the major components and their responsibilities._

**Component 1: [Name]**
- **Purpose**: What does it do?
- **Responsibilities**: Key functions
- **Interfaces**: How does it interact with other components?
- **Technology**: Implementation details

**Component 2: [Name]**
- **Purpose**: What does it do?
- **Responsibilities**: Key functions
- **Interfaces**: How does it interact with other components?
- **Technology**: Implementation details

### Data Model
_Describe the data structures, database schemas, or key entities._

**Entity 1: [Name]**
- Field 1: Type, description
- Field 2: Type, description
- Relationships: How it relates to other entities

**Entity 2: [Name]**
- Field 1: Type, description
- Field 2: Type, description
- Relationships: How it relates to other entities

### Design Decisions

**Decision 1: Branch-Based Environment Tracking**
- **Rationale**: Using Git branches to track environment state eliminates the need for separate tracking mechanisms (database tables, metadata files, tags)
- **Benefits**:
  - Git diff automatically shows what needs to be promoted
  - Merge commits provide natural checkpoints for releases
  - Branch history shows exactly when changes were promoted
  - Built-in rollback via git revert
- **Trade-offs**: Requires discipline to only commit after applying changes to corresponding database

**Decision 2: Manual SQL Execution**
- **Rationale**: Manual execution provides safety and control for database changes
- **Benefits**:
  - Human review before execution
  - Ability to time execution around maintenance windows
  - Flexibility to handle environment-specific variations
- **Trade-offs**: Requires manual step in deployment process

**Decision 3: Single Repository for All Schemas**
- **Rationale**: Centralized tracking allows coordinating changes across multiple databases
- **Benefits**:
  - Cross-database changes coordinated in single PR
  - Single release file simplifies deployment
  - Chronological ordering maintained across all schemas
- **Trade-offs**: Large repository over time, but Git handles this well

---

## Git Workflow

### Branching Strategy

**Core Concept:** Each Git branch represents the current state of its corresponding database environment.

**Branch-Environment Mapping:**
- `dev` branch = dev database state
- `qa` branch = qa database state
- `prod` branch = prod database state

**Critical Rule:** Developers MUST apply database changes to the corresponding environment BEFORE committing to that environment's branch. This ensures branch state always reflects actual database state.

**Commit Timestamps Determine Order:**
- Release files order changes by **Git commit timestamp** (when changes were committed to Git)
- This ensures chronological ordering is preserved regardless of when/where repository is cloned
- File naming conventions are recommended for human readability but don't affect functional ordering
- Filesystem creation dates are NOT used (they reset on clone)

### Development Workflow

**Step 1: Make Change in Dev Environment**
1. Developer makes database change directly in dev database
2. Developer creates SQL file with the change
3. Developer tests the change in dev environment
4. Developer commits SQL file to `dev` branch
5. **Result**: `dev` branch now contains the change, indicating it exists in dev database

**Step 2: Promote Dev → QA**
1. Manager creates pull request: `dev` → `qa`
2. Team reviews PR (includes all SQL changes since last promotion)
3. PR is merged to `qa` branch
4. **GitHub Actions triggers automatically on merge**
5. Workflow detects all NEW changes using git diff: `qa@{before-merge}...qa@{after-merge}`
6. Workflow generates release file with all changes in chronological order (sorted by Git commit timestamp)
7. Manager downloads release file from GitHub Actions artifacts
8. Manager executes release file in qa database
9. **Result**: `qa` branch now contains all changes that have been applied to qa database

**Step 3: Promote QA → Prod** (same process)
1. Manager creates pull request: `qa` → `prod`
2. Team reviews PR (includes all SQL changes since last prod promotion)
3. PR is merged to `prod` branch
4. GitHub Actions triggers automatically on merge
5. Workflow generates release file with changes
6. Manager executes release file in prod database
7. **Result**: `prod` branch now contains all changes applied to prod database

### What Gets Promoted

**Git diff determines what needs applying:**
- When merging `dev` → `qa`, git diff shows all changes in dev that aren't in qa yet
- Release file contains ONLY those new changes
- Already-promoted changes (existing in qa branch) are automatically excluded

**Example:**
```bash
# Before promotion:
# dev branch: change1.sql, change2.sql, change3.sql
# qa branch: change1.sql

# After merging dev → qa:
# Release file contains: change2.sql, change3.sql (only the NEW changes)
# qa branch now has: change1.sql, change2.sql, change3.sql
```

### Preventing Duplicate Applications

**Problem Solved:** How do we prevent applying the same change twice?

**Solution:** Git merge behavior naturally prevents duplicates:
1. Once a change is merged from `dev` → `qa`, that commit exists in qa branch
2. Next time we merge `dev` → `qa`, git diff only shows commits that AREN'T in qa yet
3. Already-merged commits are excluded automatically
4. No manual tracking needed

**Example Timeline:**
```
Day 1:
  - Developer commits change1.sql to dev branch
  - Dev database has change1 applied

Day 2:
  - Manager merges dev → qa
  - Release file contains: change1.sql
  - Manager applies change1 to qa database
  - qa branch now contains change1.sql

Day 3:
  - Developer commits change2.sql to dev branch
  - Dev database has change2 applied

Day 4:
  - Manager merges dev → qa
  - Release file contains: change2.sql (NOT change1 - it's already in qa branch)
  - Manager applies change2 to qa database
  - qa branch now contains change1.sql, change2.sql
```

### Tracking Applied Changes

**Problem Solved:** How do we track what changes have been applied to each environment?

**Solution:** Branch state = database state
- If a SQL file exists in `dev` branch, that change is in dev database
- If a SQL file exists in `qa` branch, that change is in qa database
- If a SQL file exists in `prod` branch, that change is in prod database

**Benefits:**
- No separate tracking system needed
- Git history shows exactly when changes were promoted
- `git log` shows full audit trail
- `git diff dev..qa` shows what needs to be promoted to qa
- `git diff qa..prod` shows what needs to be promoted to prod

### Rollback Strategy

**Code Rollback (Git-Based):**
- Use `git revert` to undo a commit (creates new commit that reverses changes)
- Use `git reset` to move branch pointer back (only for branches not yet merged)
- Branch can be reset to previous state if needed

**Database Rollback:**
- Create new SQL file with rollback logic (reverse the change)
- Commit rollback SQL to appropriate branch
- Execute rollback SQL in database
- **Note**: Not all database changes are reversible (data deletions, type changes, etc.)

**Important Notes:**
- Git rollback doesn't automatically rollback database - manual SQL execution still required
- Some database changes can't be safely rolled back (e.g., column drops with data loss)
- Best practice: Test changes in dev/qa before prod promotion
- Consider creating explicit rollback SQL files for critical changes

### Important Rules

**DO:**
- ✅ Apply database change to environment BEFORE committing to corresponding branch
- ✅ Commit SQL files immediately after applying to database
- ✅ Use descriptive commit messages explaining the change
- ✅ Create pull requests for all promotions (dev → qa, qa → prod)
- ✅ Review release files before executing in target database
- ✅ Execute entire release file in target database after promotion

**DON'T:**
- ❌ Commit SQL files to a branch before applying to corresponding database
- ❌ Skip environments (don't merge dev → prod directly)
- ❌ Manually apply changes to qa/prod without merging through Git
- ❌ Cherry-pick individual changes between branches (breaks chronological order)
- ❌ Rewrite history on branches that have been merged to other environments

### Benefits of This Approach

#### Operational Benefits

1. **Eliminates Single Point of Failure**
   - No dependency on individual's local computer or availability
   - Team can continue database promotions even if person on vacation, sick, or leaves company
   - Central repository accessible to all authorized team members
   - Reduces organizational risk and improves team resilience

2. **Integrates with Existing Release Note System**
   - Database changes tracked in Git just like application code
   - Existing release note generator automatically includes database changes
   - Unified release notes show complete deployment picture (code + database)
   - Jira issue references work across both code and database changes

3. **Reduces Manual Effort**
   - No manual list maintenance required
   - Git automatically tracks all changes
   - Automated release file generation (no manual compilation)
   - Copy-paste execution replaces manual change selection

4. **Enables Team Collaboration**
   - Multiple developers can make database changes
   - PR review process for database changes (peer review)
   - Clear visibility into what changes are pending
   - Shared responsibility vs single owner

#### Technical Benefits

5. **No Separate Tracking System**: Git IS the tracking system
6. **Automatic Duplicate Prevention**: Git merge behavior prevents re-including changes
7. **Clear Environment State**: Branch shows exactly what's in each environment
8. **Audit Trail**: Git history provides complete record of promotions (timestamps, authors, reasons)
9. **Enhanced Traceability**: Commit messages in compiled SQL headers show exactly what each change does and why
10. **Rollback Capability**: Git revert/reset for code, explicit SQL for database
11. **Change Visibility**: Git diff shows exactly what needs to be promoted
12. **Simple Workflow**: Developers already understand Git branching
13. **Version Controlled**: Changes can't be lost (backed up, replicated)

---

## Workflow

### Process Flow

**Workflow 1: Development to Production Promotion Flow**

1. **Developer Makes Change in Dev**
   - Input: Database change needed in dev environment
   - Process:
     - Developer executes SQL directly in dev database
     - Developer creates SQL file with the change
     - Developer tests the change in dev environment
     - **Developer commits SQL file to dev branch ONLY AFTER applying to dev database**
   - Output: SQL change file tracked in Git on dev branch, dev database updated
   - **Branch State**: `dev` branch now contains this change, indicating it exists in dev database

2. **Promote Dev → QA (Merge-Based)**
   - Input: Dev branch with SQL change files (across all schema folders), QA branch
   - Process:
     - Manager creates pull request from dev to qa
     - **If naming validation enabled**: PR triggers naming validation workflow
       - Workflow checks all SQL files match naming convention
       - Fails PR status check if non-compliant files found
       - Developer must fix naming before merge can proceed
     - Team reviews PR (sees all SQL changes since last promotion)
     - **Required status checks must pass** (naming validation, if enabled)
     - **Branch protection enforces PR approval** (for qa/prod)
     - PR is merged to qa branch
     - **GitHub Actions workflow triggers automatically on merge to qa**
     - Workflow uses git diff to identify ALL NEW changes: `qa@{before-merge}...qa@{after-merge}`
     - Workflow scans ALL schema folders (auth, application, integrations, tenants)
     - Workflow identifies SQL files added in the merge (not already in qa)
     - **Workflow sorts SQL files chronologically by Git commit timestamp** (NOT filename or filesystem dates)
     - Preserves original commit order regardless of when/where repository was cloned
     - Workflow concatenates SQL files into single release file
     - Workflow adds metadata comments (commit hash, commit message, commit timestamp, authors, schema folder)
   - Output: Single release SQL file available as GitHub Actions artifact (contains ONLY new changes)
   - **Key Concept**: Git diff automatically excludes changes already in qa branch

3. **Execute Changes in QA**
   - Input: Release SQL file from GitHub Actions
   - Process:
     - Manager downloads release file from workflow artifacts
     - Manager reviews SQL for safety
     - Manager copies SQL and pastes into qa database
     - Manager verifies changes were applied correctly
   - Output: QA database updated with all new changes from dev
   - **Branch State**: `qa` branch now contains all changes that exist in qa database

4. **Promote QA → Prod (Merge-Based, same process)**
   - Input: QA branch with SQL change files, Prod branch
   - Process:
     - Manager creates pull request from qa to prod
     - Team reviews PR (sees all SQL changes since last prod promotion)
     - PR is merged to prod branch
     - GitHub Actions triggers on merge to prod
     - Workflow uses git diff to identify changes: `prod@{before-merge}...prod@{after-merge}`
     - Workflow generates release file with ONLY new changes (not already in prod)
   - Output: Release SQL file for prod deployment
   - **Key Concept**: Only changes NEW to prod are included, already-promoted changes are excluded

5. **Execute Changes in Prod**
   - Input: Release SQL file for prod
   - Process:
     - Manager downloads release file from workflow artifacts
     - Manager reviews SQL with extra caution
     - Manager coordinates execution timing (maintenance window, etc.)
     - Manager copies SQL and pastes into prod database
     - Manager verifies changes were applied correctly
   - Output: Prod database updated with all new changes from qa
   - **Branch State**: `prod` branch now contains all changes that exist in prod database

**Workflow 2: Manual Release File Generation**

1. **Trigger Manual Workflow**
   - Input: Start date/commit and end date/commit
   - Process:
     - User navigates to GitHub Actions
     - User triggers manual workflow with date range parameters
     - Workflow scans ALL schema folders (auth, application, integrations, tenants)
     - Workflow identifies SQL files across all schemas in specified range
     - Workflow sorts files chronologically and generates release file
   - Output: Single release SQL file available as artifact (contains changes from all schemas in chronological order with commit messages)

### Error Handling

- **Missing SQL File Metadata**: If SQL file lacks proper naming/structure, skip with warning in release file comments
- **Duplicate Changes**: If same change appears multiple times (e.g., in merge conflicts), include only first occurrence with warning
- **Invalid SQL Syntax**: No pre-validation - let database handle syntax errors during execution (fail fast)
- **Failed Database Execution**: Manual rollback required - engineer must create rollback SQL and commit as new change
- **Workflow Failure**: GitHub Actions logs capture errors; workflow fails visibly; no partial release files generated

---

## Technical Requirements

### Dependencies

- **Git**: Version control system (required for all repository operations)
- **GitHub Actions**: CI/CD platform (required for automated release generation)
- **Bash/Shell**: Required for workflow scripts (available in GitHub Actions runners)

### Environment Requirements

- **Repository Platform**: GitHub (required for Actions, branch protection, pull requests)
- **Runtime**: No runtime dependencies - pure Git/SQL workflow
- **Database**: MySQL 8.0+ (target database for SQL execution)
  - Target databases: `auth`, `app_central`, `integrations`, `orchestrator`, `documents`, plus client schemas

### GitHub Configuration

**Branch Protection Settings:**

Required repository settings in GitHub for enforcing workflow:

1. **Settings → Branches → Branch protection rules**

   **Rule for `prod` branch:**
   - Require pull request reviews before merging: **Yes**
   - Required approving reviews: **1** (at least)
   - Require status checks to pass: **Yes**
   - Status checks: `validate-naming` (if naming enforcement enabled)
   - Require branches to be up to date before merging: **Yes**
   - Require conversation resolution before merging: **Recommended**
   - Restrict who can push to matching branches: **Optional** (limit to admins/release managers)
   - Allow force pushes: **No**
   - Allow deletions: **No**

   **Rule for `qa` branch:**
   - Require pull request reviews before merging: **Optional** (No, but recommended)
   - Require status checks to pass: **Yes**
   - Status checks: `validate-naming` (if naming enforcement enabled)
   - Require branches to be up to date before merging: **Yes**
   - Allow force pushes: **No**
   - Allow deletions: **No**

   **Rule for `dev` branch:**
   - **TBD** based on team preference and workflow
   - **Option A**: No protection rules (allow direct commits for fast development)
   - **Option B**: Require PRs and status checks (better tracking, more overhead)

2. **Settings → Actions → General**
   - **Allow GitHub Actions**: Yes
   - **Workflow permissions**: Read and write permissions (required for creating artifacts)
   - **Allow GitHub Actions to create and approve pull requests**: No (not needed)

**Required Status Checks:**

If SQL naming validation workflow is enabled (optional):
- Add `validate-naming` as a required status check for pull requests to `qa` and `prod` branches
- Configuration: Settings → Branches → [branch rule] → Status checks → Search for `validate-naming`

### Configuration

No environment variables or configuration files required for basic operation.

**Optional Workflow Configuration:**

If implementing the naming validation workflow:

| Variable | Required | Default | Description |
|----------|----------|---------|-------------|
| `NAMING_PATTERN` | No | `YYYYMMDD_HHMM_*.sql` | Regex pattern for SQL file naming |
| `VALIDATION_MODE` | No | `blocking` | Validation mode: `blocking` (fails PR) or `warning` (comment only) |
| `EXCLUDE_BRANCHES` | No | None | Branches to exclude from validation (e.g., `dev`) |

### Performance Requirements

- **Workflow Execution Time**: < 2 minutes for typical release generation
- **Repository Size**: Scalable to thousands of SQL files over years
- **Concurrent Workflows**: Support multiple PRs with parallel release generation
- **Git Operations**: Efficient diff operations on large commit histories

Performance is not a primary concern as operations are infrequent (deployments, not continuous traffic).

### Security Requirements

**Authentication:**
- GitHub account authentication required for all repository access
- Personal access tokens (PATs) or SSH keys for Git operations
- GitHub Actions uses GITHUB_TOKEN for workflow operations

**Authorization:**
- Repository access controls via GitHub teams/collaborators
- Branch protection enforces review requirements before merging
- Admin-only settings for branch protection rules

**Data Protection:**
- SQL files may contain sensitive schema information - use private repository
- Database integrations are NEVER stored in repository
- Manual SQL execution prevents exposure of connection strings in CI/CD
- Release files generated as artifacts (private to repository members)

**Audit Logging:**
- Git commit history provides full audit trail of all changes
- Pull requests log all promotions with review/approval records
- GitHub Actions logs capture all workflow executions
- Merge commits indicate exact time of environment promotions
- Branch history shows who applied what changes and when

**Security Best Practices:**
- Never commit database integrations or connection strings
- Review all SQL changes in PRs before merging (especially for prod)
- Use least-privilege access for repository collaborators
- Enable two-factor authentication for all team members
- Monitor GitHub audit log for suspicious activity

---

## Examples

### Example 0: Release Artifact Structure

**Scenario**: Understanding what gets generated when a release is created.

**GitHub Release Structure:**

When merging to qa or prod, GitHub Actions creates a release with the following structure:

```
Release: QA - 2025.10.15.1439
Tag: qa-2025.10.15.1439

Assets (3 files):
1. release-qa-2025.10.15.1439.sql (15 KB)
   - Compiled SQL file with all changes
   - Copy-paste ready for execution
   - Main file for deployment

2. release-qa-2025.10.15.1439-individual-files.zip (12 KB)
   - ZIP archive of all individual SQL files
   - Preserves original folder structure (auth/, integrations/, etc.)
   - For reference/audit purposes
   - Allows viewing individual changes if needed

3. Release Notes (auto-generated)
   - Created by GitHub from commit messages
   - Shows all commits between this release and last release
   - Provides context for what changed
```

**Release Naming Convention:**

- **Format**: `{ENVIRONMENT} - {YEAR}.{MONTH}.{DAY}.{HHMM}`
- **Environment values**: `DEV`, `QA`, `PROD`
- **24-hour time format** (no colons for file compatibility)
- **Examples**:
  - `QA - 2025.10.15.1439`
  - `PROD - 2025.10.16.0930`

**Optional additions** (not currently implemented but could be):
- Short commit hash: `QA - 2025.10.15.1439 (abc1234)`
- Commit message snippet: `QA - 2025.10.15.1439 - Add user roles`

**Where to Find Releases:**
1. Navigate to repository on GitHub
2. Click "Releases" (right sidebar or top navigation)
3. Find the release by environment and timestamp
4. Download the compiled SQL file for execution
5. Download the ZIP if you need to see individual files
6. Read the release notes for commit history

**Using the Assets:**

- **Compiled SQL** - Main file for deployment
  - Download this file
  - Review for safety
  - Copy and paste into target database(s)

- **ZIP Archive** - Reference/audit
  - Download if you need to see individual changes
  - Useful for understanding what changed in each file
  - Preserves original structure for traceability

- **Release Notes** - Context
  - Read to understand what commits are included
  - Shows developer names, commit messages, dates
  - Helpful for deployment planning

**Key Points:**
- Compiled SQL is the "main" file for execution
- ZIP is for reference/audit trail
- Release notes provide context from commits
- Tag name makes it easy to identify when/where release was deployed
- All assets are permanent (unlike GitHub Actions artifacts which expire)

### Example 1: Multi-Schema Release File Generation

**Scenario**: Promoting changes from dev to qa after a sprint with changes across multiple databases.

**Input Files in Repository:**
```
auth/20251015_1200_add_user_role_column.sql
integrations/20251015_1415_add_token_attribute.sql
application/20251016_0900_add_company_index.sql
auth/20251016_1530_insert_default_roles.sql
tenants/20251017_1100_add_campaign_field.sql
```

**Process:**
1. Developer merges dev branch to qa branch
2. GitHub Actions workflow triggers on merge
3. Workflow scans all schema folders (auth, application, integrations, tenants)
4. Workflow identifies all SQL files added since last qa release
5. **Workflow sorts files by Git commit timestamp** (chronological order, NOT by filename):
   - 2025-10-15 12:00:00 - auth change (commit timestamp)
   - 2025-10-15 14:15:00 - integrations change (commit timestamp)
   - 2025-10-16 09:00:00 - application change (commit timestamp)
   - 2025-10-16 15:30:00 - auth change (commit timestamp)
   - 2025-10-17 11:00:00 - tenants change (commit timestamp)
6. Workflow compiles into single release file with metadata

**Note**: File naming (e.g., `20251015_1200_...` vs `add_user_role_column.sql`) doesn't affect ordering - only Git commit timestamp matters

**Output (release-qa-20251017.sql):**
```sql
-- ============================================================
-- Database Changelog Release: QA
-- Generated: 2025-10-17 14:30:00
-- Branch: qa
-- Total Changes: 5
-- ============================================================

-- ============================================================
-- Change 1/5
-- Schema: auth
-- File: auth/20251015_1200_add_user_role_column.sql
-- Commit: a1b2c3d4
-- Message: Add user role column for RBAC support
-- Author: john.doe@example.com
-- Date: 2025-10-15 12:00:00
-- ============================================================

ALTER TABLE users ADD COLUMN default_role_id INT NULL;
ALTER TABLE users ADD FOREIGN KEY (default_role_id) REFERENCES role(id);

-- ============================================================
-- Change 2/5
-- Schema: integrations
-- File: integrations/20251015_1415_add_token_attribute.sql
-- Commit: e5f6g7h8
-- Message: Add new token attribute for LLM descriptions
-- Author: jane.smith@example.com
-- Date: 2025-10-15 14:15:00
-- ============================================================

ALTER TABLE token_attributes ADD COLUMN llm_context TEXT NULL;

-- ============================================================
-- Change 3/5
-- Schema: application
-- File: application/20251016_0900_add_company_index.sql
-- Commit: i9j0k1l2
-- Message: Add index on company_id for performance
-- Author: john.doe@example.com
-- Date: 2025-10-16 09:00:00
-- ============================================================

CREATE INDEX idx_user_company ON app_users(company_id);

-- ============================================================
-- Change 4/5
-- Schema: auth
-- File: auth/20251016_1530_insert_default_roles.sql
-- Commit: m3n4o5p6
-- Message: Insert default system roles
-- Author: jane.smith@example.com
-- Date: 2025-10-16 15:30:00
-- ============================================================

INSERT INTO role (name, description) VALUES
  ('admin', 'System administrator with full access'),
  ('user', 'Standard user with limited access'),
  ('viewer', 'Read-only access');

-- ============================================================
-- Change 5/5
-- Schema: tenants
-- File: tenants/20251017_1100_add_campaign_field.sql
-- Commit: q7r8s9t0
-- Message: Add campaign status field for all clients
-- Author: john.doe@example.com
-- Date: 2025-10-17 11:00:00
-- ============================================================

ALTER TABLE campaign ADD COLUMN status VARCHAR(50) DEFAULT 'active';

-- ============================================================
-- End of Release
-- ============================================================
```

**Key Points:**
- Single release file contains changes from ALL schemas
- Changes ordered chronologically (as they were originally made)
- Metadata clearly indicates which schema each change targets
- Engineer can copy-paste entire file and execute against appropriate databases
- Dependencies preserved through chronological ordering

### Example 2: Manual Release for Hotfix

**Scenario**: Critical bug requires emergency database fix in production.

**Input:**
- Manual workflow trigger with date range: 2025-10-18 14:00 to 2025-10-18 15:00
- Single hotfix file: `integrations/20251018_1430_fix_token_visibility.sql`

**Process:**
1. Developer triggers manual GitHub Actions workflow
2. Specifies date range covering the hotfix commit
3. Workflow scans all schema folders for changes in date range
4. Finds single change in integrations folder
5. Generates minimal release file

**Output (hotfix-prod-20251018.sql):**
```sql
-- ============================================================
-- Database Changelog Release: HOTFIX
-- Generated: 2025-10-18 15:30:00
-- Date Range: 2025-10-18 14:00:00 to 2025-10-18 15:00:00
-- Total Changes: 1
-- ============================================================

-- ============================================================
-- Change 1/1
-- Schema: integrations
-- File: integrations/20251018_1430_fix_token_visibility.sql
-- Commit: u1v2w3x4
-- Message: Fix token visibility bug for public tokens
-- Author: senior.dev@example.com
-- Date: 2025-10-18 14:30:00
-- ============================================

UPDATE api_tokens SET public = 1 WHERE internal_text_id IN ('METRIC', 'DIMENSION', 'DATE_RANGE');

-- ============================================================
-- End of Release
-- ============================================================
```

**Key Points:**
- Manual workflow allows targeted release generation
- Only includes changes in specified date range
- Same format and metadata as automated releases
- Safe for emergency production deployment

---

## Testing Strategy

### Proof-of-Concept Testing

**Purpose**: This repository contains example SQL files to test and demonstrate the complete database changelog workflow.

**Testing Approach**:
1. **Example SQL Files** - Realistic database change files across all schema folders
2. **Multi-Schema Coverage** - Examples in `auth/`, `application/`, `integrations/`, `tenants/`
3. **Workflow Validation** - Test both automated (merge-triggered) and manual (date range) release generation
4. **Edge Case Testing** - Multiple files per commit, changes across all schemas, various complexity levels

**Required Example Files**:

Each schema folder should contain diverse examples to test the system comprehensively:

**auth/** - User security schema examples:
- Add role columns for RBAC support
- Insert default system roles (admin, user, viewer)
- Create audit logging tables
- Add permission tracking columns
- Simple and complex ALTER TABLE statements

**application/** - Central schema examples:
- Add indexes for performance optimization
- Create new tables for features (e.g., NLP synonym learning)
- Add columns to existing user/company tables
- Update foreign key relationships
- Mix of DDL (schema) and DML (data) changes

**integrations/** - Credentials schema examples:
- Token attribute updates (add columns to `token_attributes`)
- Data source metric additions (insert into `datasource_metric`)
- Token definition updates (modify `api_tokens`)
- API key schema changes
- Enum table updates (silent failure scenarios)

**tenants/** - Client schema examples:
- Add campaign status fields
- Create indexes on frequently queried columns
- Alter keyword tables
- Add conversion tracking columns
- Changes that apply to multiple client schemas

**Example Diversity Requirements**:
- **Various SQL operations**: CREATE TABLE, ALTER TABLE, INSERT, UPDATE, CREATE INDEX, DROP
- **Different complexity levels**: Simple single-statement changes to complex multi-statement migrations
- **Naming conventions**: Mix of timestamp-prefixed (`YYYYMMDD_HHMM_*.sql`) and descriptive names
- **Multiple files per commit**: Some commits with 2-3 related changes
- **Cross-schema coordination**: Commits that touch multiple schema folders simultaneously
- **Realistic scenarios**: Real-world database operations the team would actually perform

**Testing Scenarios**:

1. **Automated Release Generation (dev → qa)**
   - Commit multiple example files to dev branch over time
   - Create PR from dev → qa branch
   - Merge PR and verify GitHub Actions triggers
   - Download release file artifact
   - Verify all changes included in correct chronological order
   - Verify metadata comments indicate correct schema targets
   - Verify changes from all schema folders are present

2. **Automated Release Generation (qa → prod)**
   - After qa testing, create PR from qa → prod
   - Merge PR and verify workflow triggers
   - Download release file artifact
   - Verify only NEW changes (not already in prod) are included
   - Verify duplicate prevention works correctly

3. **Manual Release Generation**
   - Trigger manual workflow with specific date range
   - Specify narrow range covering only 1-2 commits
   - Verify release file contains only changes in that range
   - Test hotfix scenario (single critical change)

4. **Chronological Ordering Validation**
   - Commit files in specific order across different schema folders
   - Verify release file maintains Git commit timestamp order
   - Test multiple files in single commit (sub-ordering)
   - Test changes across all schemas are interleaved correctly by timestamp

5. **Duplicate Prevention Testing**
   - Promote same changes through dev → qa → prod
   - Verify qa release doesn't include changes already in qa
   - Verify prod release doesn't include changes already in prod
   - Confirm no duplicate applications occur

6. **Edge Case Testing**
   - Commit 3+ files in single commit, verify ordering
   - Test empty commits (no SQL changes), verify workflow handles gracefully
   - Test large release files (10+ changes), verify performance
   - Test file naming without timestamps, verify Git timestamp ordering works

**Success Criteria for PoC**:
- ✅ All example files successfully tracked in Git
- ✅ Automated workflow generates release files on qa/prod merges
- ✅ Release files contain all changes in correct chronological order
- ✅ Changes from all schema folders included and clearly labeled
- ✅ Duplicate prevention works (already-promoted changes excluded)
- ✅ Manual workflow generates targeted release files
- ✅ Generated SQL is copy-paste ready and executable
- ✅ Stakeholders can understand and validate the approach
- ✅ Workflow is simple enough for team to adopt

**Demonstration Plan**:
1. Show repository structure with example files in all schema folders
2. Demonstrate committing new change to dev branch
3. Create PR from dev → qa and show review process
4. Merge PR and show automated workflow execution
5. Download and review generated release file
6. Show metadata comments indicating schema targets
7. Demonstrate manual workflow for hotfix scenario
8. Walk through chronological ordering across schemas
9. Explain branch-based tracking (branch = database state)
10. Discuss rollback strategy and edge cases

### Unit Tests
_Future consideration: Unit tests for workflow scripts (if complexity increases)_

### Integration Tests
_Future consideration: Integration tests for multi-database execution (out of scope for PoC)_

### End-to-End Tests
_The PoC testing described above serves as end-to-end validation of the complete workflow_

---

## Proof-of-Concept Demonstration

### Purpose
This section outlines the plan for demonstrating the database changelog system to stakeholders and validating the proof-of-concept approach.

### Target Audience
- **Coworkers/Team Members**: Developers who would use the system
- **Technical Leadership**: Decision-makers evaluating the approach
- **Database Administrators**: Team members responsible for database changes
- **DevOps/Release Managers**: Team members responsible for deployments

### Demonstration Workflow

**1. Repository Overview** (5 minutes)
- Show repository structure with schema folders
- Explain branch-environment mapping (dev = dev database, qa = qa database, prod = prod database)
- Walk through example SQL files in different schema folders
- Highlight diversity of examples (simple ALTER TABLE to complex migrations)

**2. Development Workflow** (10 minutes)
- **Scenario**: Developer needs to add a new column to `users` table in dev
- **Steps**:
  1. Show dev database before change
  2. Execute SQL change in dev database
  3. Create SQL file with the change (e.g., `auth/add_user_role_column.sql`)
  4. Commit SQL file to dev branch with descriptive message
  5. Show Git history with commit timestamp
- **Key Point**: Developer commits AFTER applying to dev database (branch = database state)

**3. Dev → QA Promotion** (15 minutes)
- **Scenario**: Promoting multiple changes from dev to qa
- **Steps**:
  1. Show Git diff: `dev..qa` (what needs to be promoted)
  2. Create pull request from dev → qa
  3. Review PR (show all SQL changes since last promotion)
  4. Explain branch protection rules (required reviews, status checks)
  5. Merge PR to qa branch
  6. Show GitHub Actions workflow triggering automatically
  7. Wait for workflow completion (or show pre-recorded execution)
  8. Download release file artifact
  9. Review release file structure:
     - Header with metadata
     - Changes in chronological order (Git commit timestamp)
     - Schema folder clearly labeled for each change
     - Multiple schemas interleaved chronologically
  10. Explain how this would be executed in qa database (copy-paste)
- **Key Points**:
  - Automated workflow triggered on merge
  - Only NEW changes included (duplicate prevention)
  - All schema folders scanned and included
  - Chronological ordering across all schemas

**4. Manual Release for Hotfix** (10 minutes)
- **Scenario**: Emergency fix needed in production
- **Steps**:
  1. Navigate to GitHub Actions
  2. Trigger manual workflow
  3. Specify date range (e.g., last 2 hours)
  4. Show workflow execution
  5. Download hotfix release file
  6. Review contents (single targeted change)
- **Key Point**: Flexible manual workflow for emergency deployments

**5. QA → Prod Promotion** (5 minutes)
- **Scenario**: Promoting tested changes to production
- **Steps**:
  1. Create pull request from qa → prod
  2. Show enhanced review process for prod
  3. Merge and show workflow execution
  4. Download prod release file
  5. Explain execution timing (maintenance windows)
- **Key Point**: Same workflow, but with extra caution for production

**6. Advanced Features** (10 minutes)
- **Duplicate Prevention**:
  - Show how already-promoted changes are excluded
  - Demonstrate Git merge behavior preventing re-applications
- **Multi-Schema Coordination**:
  - Show single commit touching multiple schema folders
  - Demonstrate chronological ordering across schemas
- **Rollback Strategy**:
  - Explain git revert for code rollback
  - Show example rollback SQL file
  - Discuss limitations (not all changes reversible)

**7. Q&A and Edge Cases** (15 minutes)
- **Common Questions**:
  - What if developer forgets to commit after applying change?
  - What if two developers modify same table?
  - What if SQL file naming is inconsistent?
  - What about very large migrations (data backfills)?
  - How to handle breaking changes that affect application code?
- **Edge Case Demonstrations**:
  - Multiple files in single commit
  - Empty merge (no SQL changes)
  - File without timestamp in name (Git timestamp still works)

### Success Criteria

**Technical Validation**:
- ✅ Automated workflow successfully generates release files on merge
- ✅ Release files contain all changes in correct chronological order
- ✅ Changes from all schema folders correctly labeled and included
- ✅ Duplicate prevention works (already-promoted changes excluded)
- ✅ Manual workflow generates targeted release files for hotfixes
- ✅ Git-based ordering works regardless of file naming

**Stakeholder Buy-In**:
- ✅ Team understands the workflow and their role
- ✅ Leadership approves the approach for production use
- ✅ DBAs confirm release files are usable and safe
- ✅ DevOps confirms integration with deployment process is feasible
- ✅ Developers agree the workflow is simple enough to adopt

**Decision Outcome**:
- **GO**: Proceed with production implementation, migrate from examples to real changes
- **ITERATE**: Refine approach based on feedback, re-demonstrate
- **NO-GO**: Abandon approach, investigate alternatives

### Post-Demonstration Next Steps

**If Approved for Production**:
1. **Remove Example Files**: Clear out PoC example SQL files
2. **Update Documentation**: Finalize developer guidelines and workflow documentation
3. **Configure Branch Protection**: Enable branch protection rules for qa/prod branches
4. **Train Team**: Conduct training session for all developers
5. **Pilot with Small Team**: Start with 2-3 developers for first sprint
6. **Monitor and Iterate**: Gather feedback, refine process
7. **Full Rollout**: Expand to entire team after successful pilot

**If Needs Refinement**:
1. Collect specific feedback from stakeholders
2. Address concerns (add validation, simplify workflow, etc.)
3. Update PoC examples to demonstrate solutions
4. Schedule follow-up demonstration

**If Rejected**:
1. Document reasons for rejection
2. Explore alternative approaches (Flyway, Liquibase, custom tooling)
3. Preserve learnings for future reference

### Resources for Demonstration

**Required Materials**:
- This repository with example SQL files in all schema folders
- GitHub Actions configured and tested
- Pre-recorded workflow execution (backup if live demo fails)
- Presentation slides with architecture diagrams
- Printed handouts with workflow summary
- FAQ document with common questions

**Technical Setup**:
- Ensure GitHub Actions has run successfully at least once
- Pre-stage some changes in dev branch ready to promote
- Have example hotfix scenario prepared
- Test screen sharing and repository navigation beforehand

**Time Allocation**: Total 70 minutes
- Presentation: 55 minutes
- Q&A: 15 minutes

---

## Deployment

### Build Process
_How is the project built? What are the build steps?_

### Deployment Process
_How is the project deployed? What are the deployment steps?_

### Rollback Strategy
_How do we roll back if something goes wrong?_

---

## Monitoring and Observability

### Metrics
_What metrics should be tracked?_

- Metric 1: Description, threshold/target
- Metric 2: Description, threshold/target
- Metric 3: Description, threshold/target

### Logging
_What should be logged? At what levels?_

### Alerts
_What conditions should trigger alerts?_

---

## Future Considerations

### Potential Enhancements
_Features or improvements that are out of scope now but might be added later._

- **Production Migration**: If PoC successful, migrate to production use with real database changes
- **Automated SQL Validation**: Pre-execution syntax validation or dry-run against test database
- **Rollback SQL Generation**: Automated generation of rollback SQL for reversible changes
- **Breaking Change Detection**: Automated detection of potentially breaking schema changes
- **Deployment Coordination**: Integration with application deployment pipelines
- **Notification System**: Slack/email notifications when release files are generated
- **Change Templates**: Pre-defined templates for common database change patterns
- **Database Execution Integration**: Optional automated execution with proper safeguards
- **Multi-Repository Support**: Support for multiple projects with separate changelog repositories

### Known Limitations
_What are the current limitations or constraints?_

- **Proof-of-Concept Status**: Repository contains example files for testing, not production database changes
- **Manual SQL Execution**: Release files must be manually executed against target databases
- **No Automatic Validation**: SQL syntax/safety not validated before release file generation
- **No Rollback Automation**: Database rollbacks require manual creation of reverse SQL
- **Git Discipline Required**: System relies on developers committing to correct branch after applying changes
- **Single Repository**: All schemas tracked in one repository (could become large over time)
- **Limited Conflict Detection**: Conflicting changes between developers not automatically detected
- **No Application Coordination**: Database changes not automatically coordinated with application deployments

### Scalability Considerations
_How will this scale? What are the bottlenecks? How might we address them in the future?_

**Current PoC Scope**: Designed for testing and demonstration with example files, not large-scale production use yet.

**Potential Bottlenecks**:
- **Repository Size**: Hundreds/thousands of SQL files over years could slow Git operations
  - Mitigation: Git handles this well; consider archiving old changes if needed
- **Workflow Execution Time**: Large release files (100+ changes) may take longer to generate
  - Mitigation: Current approach is fast enough for typical deployments (< 2 minutes)
- **Manual Review Overhead**: Large release files harder to review before execution
  - Mitigation: Break into smaller, more frequent deployments
- **Merge Conflict Frequency**: More developers = more potential conflicts
  - Mitigation: Frequent merges, clear communication, PR reviews

**Scaling Path** (if PoC adopted for production):
1. Start with small team, frequent small deployments
2. Monitor repository size and workflow performance
3. Add automated validation as complexity grows
4. Consider repository splitting if single repo becomes unwieldy
5. Integrate with deployment pipelines for better coordination

---

## Open Questions

**Summary of Resolutions:**
- **✅ RESOLVED**: Questions #1 (SQL file structure), #2 (tracking applied changes), #3 (preventing duplicates), #8 (multi-database support)
- **✅ PARTIALLY RESOLVED**: Question #5 (rollback strategy) - Git-based approach established; Question #1 - Sub-decision on naming enforcement pending
- **⏳ PENDING**: Questions #4, #6, #7, #9, #10, #11, #12, #13 require decisions before implementation
- **🆕 NEW**: Questions #12 (naming convention enforcement), #13 (dev branch protection) added based on CI/CD planning

**Key Breakthrough: Branch-Based Environment Tracking**
The branching strategy (dev/qa/prod branches = database states) resolves multiple open questions:
- **#2 (Tracking)**: Branch state = database state, Git IS the tracking system
- **#3 (Duplicates)**: Git merge behavior automatically prevents duplicate applications
- **#5 (Rollback)**: Git revert provides code rollback, forward-only SQL for database rollback

**New Questions from Branch Protection & CI/CD Planning:**
- **#12 (Naming Enforcement)**: Should SQL files be required to follow naming convention? If so, blocking or warning?
- **#13 (Dev Branch Protection)**: Should dev branch require PRs or allow direct commits?

---

1. **SQL File Structure and Naming Convention** ✅ RESOLVED (with sub-decision pending)
   - Context: Need consistent way to organize and name SQL change files for easy identification and chronological ordering
   - **DECISION**: Schema-based folder structure with flexible naming (recommended but not enforced), Git commit timestamp determines order
   - **Implementation**:
     - Changes organized into schema-specific folders: `auth/`, `application/`, `integrations/`, `tenants/`
     - **Ordering Strategy**: Release files order changes by **Git commit timestamp** (not filename or filesystem creation date)
       - Git commit timestamps are reliable and persist across repository clones
       - Filesystem creation dates reset when repository is cloned
       - Ensures chronological order is maintained regardless of when/where repo is cloned
     - **Naming Convention** (RECOMMENDED but NOT ENFORCED):
       - Suggested format: `YYYYMMDD_HHMM_description.sql`
       - Purpose: Human readability, acts as file-based pseudo-log for easier browsing
       - Developers can name files however they want - Git commit timestamp determines functional ordering
       - Having date in filename helps when browsing folders but isn't functionally required
     - Release workflow scans all schema folders and compiles changes chronologically by commit timestamp
   - **Benefits**:
     - Clear separation of changes by target database
     - Chronological ordering preserved across all schemas (via Git commit timestamps)
     - Naming flexibility for developers while maintaining functional ordering
     - Reliable ordering regardless of filesystem or clone operations
     - Single release file can be copy-pasted directly into databases
   - **Resolved**: Schema-based folder approach with Git-based ordering addresses organization and multi-database tracking
   - **Sub-Decision Pending**: Should naming convention be enforced? (See Open Question #12)

2. **Tracking Applied Changes Per Environment** ✅ RESOLVED
   - Context: System needs to know what changes have been applied to each environment to generate correct release files
   - **DECISION**: Branch state = database state (branch-based tracking)
   - **Implementation**:
     - Each environment has a corresponding branch (dev, qa, prod)
     - If a SQL file exists in a branch, that change is in the corresponding database
     - Developers commit to branch ONLY AFTER applying change to database
     - Git history provides complete audit trail of when changes were promoted
   - **How It Works**:
     - Git diff between branches shows what needs to be promoted
     - Merge commits trigger automated release file generation
     - No separate tracking system needed - Git IS the tracking system
   - **Benefits**:
     - No database tracking tables needed
     - No metadata files needed
     - Git log shows full promotion history
     - `git diff dev..qa` shows what needs promotion to qa
   - **Resolved**: Branch-based approach eliminates need for separate tracking mechanism

3. **Preventing Duplicate Applications** ✅ RESOLVED
   - Context: Need to ensure same change isn't applied twice to same environment
   - **DECISION**: Git merge behavior naturally prevents duplicates
   - **Implementation**:
     - When merging dev → qa, git diff shows only commits that DON'T exist in qa yet
     - Already-merged commits are automatically excluded
     - Release file contains only NEW changes
     - No manual tracking or idempotency requirements
   - **How It Works**:
     1. Change committed to dev branch → exists in dev
     2. Merge dev → qa → change now exists in qa branch
     3. Next merge dev → qa → git diff excludes already-merged changes
     4. Release file only contains changes NOT yet in qa
   - **Benefits**:
     - No need for idempotent SQL (though still recommended)
     - No application tracking system needed
     - Git's built-in merge logic handles duplicate prevention
     - Human review still possible before execution
   - **Resolved**: Git merge mechanics eliminate duplicate applications automatically

4. **Handling Change Dependencies**
   - Context: Some database changes depend on others (e.g., add column then add index on that column)
   - Options:
     - Strict chronological: Always apply in commit order (assumes proper development order)
     - Dependency declarations: Metadata in SQL files declaring dependencies
     - Folder structure: Organize changes by dependency level
     - Single transaction: Execute entire release file as one transaction
   - Considerations: How to handle cross-file dependencies? What if dependency is in different branch?
   - **Current Implementation**: Changes ordered by Git commit timestamp (chronological order)
   - **Open Sub-Questions**:
     - What if multiple files are in a single commit? (alphabetical sub-ordering? schema folder ordering?)
     - What if commit history is rebased/amended? (use final commit timestamp?)
   - Decision by: Before implementing release file compilation

5. **Rollback Strategy** ✅ PARTIALLY RESOLVED
   - Context: Need way to undo changes if something goes wrong
   - **DECISION**: Git-based code rollback + forward-only database approach
   - **Implementation**:
     - **Code Rollback**: Use `git revert` to undo commits (creates new reversing commit)
     - **Database Rollback**: Create new SQL file with reverse logic, commit and execute
     - **Branch Rollback**: Use `git reset` on unmerged branches if needed
   - **How It Works**:
     1. Identify problematic change in Git history
     2. Use `git revert <commit>` to create reversing commit
     3. Create SQL file with rollback logic (ALTER DROP COLUMN, DELETE, etc.)
     4. Commit rollback SQL to branch
     5. Execute rollback SQL in database
     6. Promote rollback through environments like any other change
   - **Important Notes**:
     - Not all database changes are reversible (data deletions, type changes)
     - Git rollback doesn't automatically rollback database
     - Best practice: Test in dev/qa before prod promotion
     - Consider explicit rollback SQL files for critical changes
   - **Benefits**:
     - Git provides code rollback mechanism
     - Forward-only approach maintains audit trail
     - Same promotion workflow applies to rollbacks
   - **Still Open**: Automatic rollback SQL generation (out of scope for initial version)
   - **Resolved**: Basic rollback strategy established using Git + forward-only SQL

6. **Pre-Execution Validation**
   - Context: Should system validate SQL before generating release files?
   - Options:
     - No validation: Trust developers and database to catch errors
     - Syntax validation: Parse SQL to check for syntax errors
     - Dry-run validation: Execute against test database before generating release
     - Static analysis: Check for common anti-patterns (DROP, DELETE without WHERE, etc.)
   - Considerations: How to validate without database connection? What validation level is appropriate?
   - Decision by: Before implementing release file generation

7. **Handling Conflicts and Breaking Changes**
   - Context: What if two developers create conflicting changes? What about schema changes that break application code?
   - Options:
     - Manual resolution: Developers resolve conflicts during PR review
     - Conflict detection: Automated detection of conflicting changes
     - Breaking change warnings: Flag potentially breaking changes for review
     - Deployment coordination: Require application code deployment before/after database changes
   - Considerations: How to detect conflicts automatically? How to coordinate with application deployments?
   - Decision by: Before implementing automated workflow

8. **Multi-Database Support** ✅ RESOLVED
   - Context: ProductName has multiple databases (integrations, auth, app_central, orchestrator, documents)
   - **DECISION**: Single repository with schema-based folder structure
   - **Implementation**:
     - `/auth/*.sql` - User security database changes
     - `/application/*.sql` - Application database changes
     - `/integrations/*.sql` - Credentials database changes
     - `/tenants/*.sql` - Client schema changes (multiple schemas with identical structure)
   - **Release File Generation**:
     - Automated workflow scans ALL schema folders
     - Compiles changes across all schemas in chronological order
     - Single release file contains changes for all databases
     - Metadata comments indicate which schema each change targets
   - **Benefits**:
     - Centralized tracking of all database changes
     - Cross-database changes coordinated in single PR/merge
     - Chronological ordering maintained across all schemas
     - Single release file simplifies deployment process
   - **Resolved**: Folder-based approach provides clean separation while maintaining coordination

9. **Change File Granularity**
   - Context: Should each SQL file contain one change or multiple related changes?
   - Options:
     - One logical change per file: Single ALTER TABLE, single INSERT set
     - One transaction per file: Multiple related changes that must succeed/fail together
     - One feature per file: All database changes for a feature in one file
   - Considerations: How to balance traceability vs. file proliferation? How to handle atomic change sets?
   - Decision by: Before establishing developer guidelines

10. **Metadata and Documentation Requirements**
    - Context: What information should be included with each change?
    - Options:
      - Minimal: Just SQL with filename describing change
      - Comments: SQL comments with author, date, reason, related ticket
      - Separate metadata: JSON/YAML file alongside each SQL file
      - Commit messages: Rely on Git commit messages for context
    - Considerations: How much documentation is too much? How to ensure consistency?
    - Decision by: Before establishing developer guidelines

11. **Git Commit Timestamp Ordering Edge Cases**
    - Context: Using Git commit timestamp for ordering requires handling edge cases
    - **Questions to Resolve**:
      - Multiple files in single commit: How to order them? (alphabetical? schema folder order? preserve file path order?)
      - Amended/rebased commits: Use final commit timestamp or preserve original? How to handle force pushes?
      - Merge commits: Use merge commit timestamp or original commit timestamps from merged branch?
      - Clock skew: Different developer machines with incorrect clocks - rely on server-side commit timestamp?
      - Tie-breaking: If two commits have same timestamp (unlikely but possible), what's the tie-breaker?
    - Options:
      - Primary: Git commit timestamp (author date vs committer date?)
      - Sub-ordering for same commit: Alphabetical by file path, schema folder order, or undefined
      - Rebase handling: Treat rebased commits as new (use new timestamp) or preserve intent (use original author date)
    - Considerations: How to balance simplicity vs handling all edge cases? Document expected behavior for developers?
    - Decision by: Before implementing release file generation workflow

12. **SQL File Naming Convention Enforcement**
    - Context: While Git commit timestamps determine ordering, enforcing a naming convention could improve repository organization and human readability
    - **Questions to Resolve**:
      - Should naming convention be enforced at all?
        - Pros: Consistency, easier browsing, visual chronology, professional appearance
        - Cons: Adds friction to workflow, requires maintenance, reduces flexibility
      - If enforced, what format should be required?
        - Option A: `YYYYMMDD_HHMM_description.sql` (timestamp + description)
        - Option B: `YYYYMMDD_description.sql` (date only, no time)
        - Option C: Custom format per team preference
      - Should validation be blocking or warning-only?
        - Blocking: PR cannot merge until files are renamed (enforces compliance)
        - Warning: PR shows warning but can still merge (encourages compliance)
      - Which branches should enforcement apply to?
        - All branches (dev, qa, prod)
        - Only promoted branches (qa, prod)
        - Only prod branch
    - Options:
      - **Option 1**: No enforcement (current default) - Maximum flexibility, rely on Git timestamps
      - **Option 2**: Validation workflow with blocking status check - Enforces consistency
      - **Option 3**: Validation workflow with warning comments - Encourages consistency without blocking
    - Considerations:
      - Team size and experience level
      - Change frequency
      - Value of visual chronology vs. descriptive names
      - Workflow friction vs. consistency benefits
    - Decision by: Before enabling naming validation workflow
    - **Current Recommendation**: Start without enforcement (Option 1), add validation (Option 2) if consistency issues arise

13. **Dev Branch Protection Requirements**
    - Context: Need to decide whether dev branch should require pull requests or allow direct commits
    - **Questions to Resolve**:
      - Should dev branch allow direct commits?
        - Pros: Faster development workflow, less overhead for small teams
        - Cons: Less tracking, no review opportunity, easier to make mistakes
      - Should dev branch require status checks?
        - Pros: Catches issues early (naming validation, future tests)
        - Cons: Slows down development, may be overkill for dev environment
      - Should dev branch require PR reviews?
        - Pros: Code review for all changes, better knowledge sharing
        - Cons: Significant workflow overhead, slows development velocity
    - Options:
      - **Option A**: No protection (allow direct commits) - Fast development, trust developers
      - **Option B**: Require PRs without reviews - Tracking without review overhead
      - **Option C**: Require PRs with reviews - Full review process on all branches
      - **Option D**: Require status checks but not PRs - Automated validation only
    - Considerations:
      - Team size: Larger teams may benefit from more structure
      - Developer experience: Experienced teams may not need strict reviews
      - Change frequency: High frequency makes PR overhead more noticeable
      - Database risk: Dev database mistakes are low-risk compared to prod
    - Decision by: Before configuring branch protection rules
    - **Current Recommendation**: Start with no protection (Option A), add structure if needed based on team workflow

14. **Release Tag Naming - Include Commit Hash?**
    - Context: Release tags use format `{ENVIRONMENT} - {YEAR}.{MONTH}.{DAY}.{HHMM}` - should we include short commit hash?
    - **Questions to Resolve**:
      - Should short commit hash be included in tag name?
        - Example with hash: `QA - 2025.10.15.1439 (abc1234)`
        - Example without: `QA - 2025.10.15.1439`
        - Pros of including: Easy traceability to exact commit, helps with debugging
        - Cons of including: Longer tag name, less clean appearance
      - Should commit message snippet be included?
        - Example: `QA - 2025.10.15.1439 - Add user roles`
        - Pros: More context at a glance
        - Cons: Tag names get very long, commit messages may not be concise
    - Options:
      - **Option A**: Simple format only (current) - `{ENV} - {TIMESTAMP}`
      - **Option B**: Include short hash - `{ENV} - {TIMESTAMP} ({HASH})`
      - **Option C**: Include message snippet - `{ENV} - {TIMESTAMP} - {MESSAGE}`
    - Considerations:
      - Simplicity vs. information density
      - Tag names appear in many places (release list, git commands, etc.)
      - Commit hash is always available in release details anyway
      - Release notes provide full context
    - Decision by: Before implementing release generation workflow
    - **Current Recommendation**: Keep simple format (Option A) - hash and context available in release details

---

## References

### Documentation
_Links to relevant documentation, RFCs, or external resources._

- [Reference 1](url): Description
- [Reference 2](url): Description
- [Reference 3](url): Description

### Related Projects
_Links to related projects or repositories._

- [Project 1](url): Description
- [Project 2](url): Description

---

## Revision History

| Date       | Author | Changes |
|------------|--------|---------|
| YYYY-MM-DD | Name   | Initial draft |

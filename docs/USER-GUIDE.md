# Database Changelog User Guide

Welcome! This guide will help you use the database changelog system to track and promote database changes across environments.

---

## Table of Contents

1. [Quick Start](#quick-start)
2. [For Developers](#for-developers)
3. [For Managers/Release Coordinators](#for-managersrelease-coordinators)
4. [Release File Generation](#release-file-generation)
5. [Schema Folders](#schema-folders)
6. [Common Workflows](#common-workflows)
7. [Important Rules & Best Practices](#important-rules--best-practices)
8. [FAQ / Troubleshooting](#faq--troubleshooting)
9. [GitHub Actions Workflows](#github-actions-workflows)

---

## Quick Start

Get started in 5 minutes:

### 1. Clone the Repository
```bash
git clone <repository-url>
cd database-changelog-test
```

### 2. Understand the Branches
- **dev branch** = Development database state
- **qa branch** = QA database state
- **prod branch** = Production database state

> **Key Concept:** If a SQL file exists in a branch, that change has been applied to the corresponding database.

### 3. Understand the Schema Folders
```
database-changelog-test/
├── auth/              # User security database changes
├── application/   # Application database changes
├── integrations/          # Credentials database changes
├── tenants/       # Client schema changes
└── docs/                 # Documentation
```

### 4. Ready to Make a Change?
Jump to [For Developers](#for-developers) section below.

---

## For Developers

### Daily Workflow: Making a Database Change

**CRITICAL RULE:** Always apply database changes to the environment **BEFORE** committing to Git.

#### Step-by-Step Process

**1. Apply the Change to Dev Database**

First, execute your SQL directly in the dev database:
```sql
-- Example: Add a new column to users table in auth database
ALTER TABLE users ADD COLUMN default_role_id INT NULL;
ALTER TABLE users ADD FOREIGN KEY (default_role_id) REFERENCES role(id);
```

**2. Test the Change**

Verify the change works correctly in your dev environment:
- Check the schema was updated
- Test application functionality
- Confirm no errors

**3. Create a SQL File**

Create a new SQL file with your change in the appropriate schema folder:
```bash
# Recommended naming (timestamp helps with browsing):
auth/20251015_1200_add_user_role_column.sql

# Or use a descriptive name (Git commit timestamp determines order):
auth/add_user_role_column.sql
```

**File contents:**
```sql
-- Add default_role_id to users for authorization support
ALTER TABLE users ADD COLUMN default_role_id INT NULL;
ALTER TABLE users ADD FOREIGN KEY (default_role_id) REFERENCES role(id);
```

**4. Commit to Dev Branch**

Commit the SQL file to the dev branch with a descriptive message:
```bash
git checkout dev
git add auth/20251015_1200_add_user_role_column.sql
git commit -m "Add default_role_id column to users for authorization support"
git push origin dev
```

> **Important:** The Git commit timestamp determines the order of changes in release files, NOT the filename.

**5. Done!**

Your change is now tracked in Git and ready to be promoted to QA when the next release happens.

---

### Which Schema Folder to Use?

| Folder | Database | Use For |
|--------|----------|---------|
| `auth/` | Authentication database | Authentication, authorization, user management, roles, permissions, audit trails |
| `application/` | Application database | Business logic, user data, companies, core application features, application data |
| `integrations/` | Integration database | Token definitions, data sources, metrics, dimensions, API integrations |
| `tenants/` | Tenant databases | Client-specific schema changes that apply to multiple client databases |

**Example:**
- Adding a column to `users` table → `auth/`
- Adding a column to `app_users` table → `application/`
- Adding a new token attribute → `integrations/`
- Adding a campaign field for clients → `tenants/`

---

### File Naming Recommendations

**Recommended Format:**
```
YYYYMMDD_HHMM_description.sql
```

**Examples:**
```
auth/20251015_1200_add_user_role_column.sql
integrations/20251015_1415_add_token_attribute.sql
application/20251016_0900_add_company_index.sql
```

**Why use timestamps?**
- Easier to browse files chronologically in file explorer
- Immediate visual indication of when change was made
- Consistent across the team

**Can I use other naming?**
Yes! The filename doesn't affect the functional ordering of changes. Git commit timestamps determine the order in release files. Use descriptive names if you prefer:
```
auth/add_user_role_column.sql
integrations/add_llm_context_field.sql
```

---

### Important Rules for Developers

**DO:**
- ✅ **Apply to database FIRST, commit to Git SECOND**
- ✅ Test your change in dev before committing
- ✅ Use descriptive commit messages
- ✅ Put SQL file in the correct schema folder
- ✅ Keep changes focused and atomic
- ✅ Commit immediately after applying to database

**DON'T:**
- ❌ **NEVER commit SQL to Git before applying to database**
- ❌ Don't skip testing in dev
- ❌ Don't put SQL files in wrong schema folder
- ❌ Don't make changes directly in qa/prod databases (use promotion workflow)
- ❌ Don't cherry-pick changes between branches (breaks ordering)

---

## For Managers/Release Coordinators

### Promoting Changes: Dev → QA

**When:** After a sprint or when changes are ready for QA testing.

#### Step-by-Step Process

**1. Create Pull Request**

Create a PR from dev to qa:
```bash
# On GitHub:
# 1. Navigate to repository
# 2. Click "Pull requests" → "New pull request"
# 3. Base: qa, Compare: dev
# 4. Click "Create pull request"
```

**2. Review the PR**

The PR shows all SQL changes since the last QA promotion:
- Review which files changed
- Check commit messages for context
- Verify changes look safe
- Get required approvals (if branch protection enabled)

**3. Merge the PR**

Once approved, merge the PR to qa branch:
- Click "Merge pull request"
- Confirm the merge

> **Automatic:** GitHub Actions workflow triggers automatically on merge!

**4. Download the Release Assets**

The workflow creates a GitHub Release:
1. Navigate to "Releases" in GitHub (right sidebar or top navigation)
2. Find the latest release (e.g., "QA - 2025.10.15.1439")
3. Download the assets:
   - **Compiled SQL file** (e.g., `release-qa-2025.10.15.1439.sql`) - Main file for execution
   - **ZIP archive** (optional, for reference) (e.g., `release-qa-2025.10.15.1439-individual-files.zip`)
4. Review the auto-generated release notes for commit context

**5. Review the Release File**

Open the downloaded SQL file and review:
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
-- Message: Add user role column for authorization support
-- Author: john.doe@example.com
-- Date: 2025-10-15 12:00:00
-- ============================================================

ALTER TABLE users ADD COLUMN default_role_id INT NULL;
-- ... more changes below ...
```

**6. Execute in QA Database**

For each schema mentioned in the release file:

**Example for auth database:**
```bash
# Connect to QA auth database
mysql -h qa-database-host -u username -p auth

# Copy and paste the SQL for auth changes
# (Look for "Schema: auth" in the release file)
```

**Example for integrations database:**
```bash
# Connect to QA integrations database
mysql -h qa-database-host -u username -p integrations

# Copy and paste the SQL for integrations changes
# (Look for "Schema: integrations" in the release file)
```

> **Tip:** The release file contains changes for ALL databases in chronological order. Execute changes for each database in the order they appear in the file.

**7. Verify Changes Applied**

After executing, verify:
- All SQL executed without errors
- Schema changes are present
- Application works correctly in QA

**8. Done!**

QA database is now up to date with dev changes. The qa branch now reflects the state of the QA database.

---

### Promoting Changes: QA → Prod

**When:** After QA testing is complete and changes are ready for production.

The process is **identical to Dev → QA**, just with different branches:

1. Create PR: qa → prod
2. Review PR (more carefully for production!)
3. Merge PR (triggers GitHub Actions automatically)
4. Download release file artifact
5. Review release file thoroughly
6. **Coordinate timing** (maintenance window, off-peak hours, etc.)
7. Execute in prod databases
8. Verify changes applied
9. Monitor application for issues

> **Warning:** Production changes should be executed during planned maintenance windows. Coordinate with the team and notify stakeholders.

---

### Manual Release Generation

**When:** For hotfixes or when you need a release file outside the normal promotion flow.

#### Step-by-Step Process

**1. Trigger the Manual Workflow**

1. Navigate to repository on GitHub
2. Click "Actions" tab
3. Click "Manual Release Generation" workflow (left sidebar)
4. Click "Run workflow" button (right side)
5. Fill in parameters:
   - **Branch:** Which branch to generate from (e.g., `dev`, `qa`, `prod`)
   - **Start date:** Beginning of date range (e.g., `2025-10-15 14:00:00`)
   - **End date:** End of date range (e.g., `2025-10-15 16:00:00`)
6. Click "Run workflow"

**2. Wait for Workflow to Complete**

The workflow will:
- Scan all schema folders for changes in the date range
- Compile changes chronologically
- Generate release file

**3. Download Release Assets**

1. Navigate to "Releases" tab
2. Find the manual release
3. Download the compiled SQL file (e.g., `hotfix-prod-20251015.sql`)
4. Optionally download ZIP archive for reference

**4. Execute in Target Database**

Follow the same execution process as automated releases:
- Review the SQL
- Copy and paste into appropriate databases
- Verify changes applied

**Example Hotfix Scenario:**
```
Scenario: Critical bug in production requires urgent database fix

1. Developer creates hotfix SQL file
2. Developer commits to hotfix branch
3. Manager triggers manual workflow:
   - Branch: hotfix
   - Start: 2025-10-15 14:00:00 (just before the fix)
   - End: 2025-10-15 16:00:00 (just after the fix)
4. Download release file (contains only the hotfix)
5. Execute in prod database immediately
6. Later: Merge hotfix to dev/qa/prod branches to keep them in sync
```

---

## Release File Generation

### How It Works

**Automatic Generation (Recommended):**
- Triggers on merge to qa or prod branches
- Scans all schema folders for NEW changes
- Compiles changes chronologically by Git commit timestamp
- Creates a GitHub Release with 3 assets:
  1. **Compiled SQL file** - Single file with all changes (main file for execution)
  2. **ZIP archive** - All individual SQL files in original folder structure (for reference)
  3. **Release notes** - Auto-generated from commit messages (provides context)

**Release Naming:**
- Format: `{ENVIRONMENT} - {YEAR}.{MONTH}.{DAY}.{HHMM}`
- Examples: `QA - 2025.10.15.1439`, `PROD - 2025.10.16.0930`
- Tag: `{environment}-{timestamp}` (e.g., `qa-2025.10.15.1439`)

**What the Compiled SQL File Contains:**
```sql
-- Header with metadata
-- ============================================================
-- Database Changelog Release: QA
-- Generated: 2025-10-15 14:30:00
-- Branch: qa
-- Total Changes: 5
-- ============================================================

-- For each change:
-- ============================================================
-- Change 1/5
-- Schema: auth                          ← Which database
-- File: auth/add_column.sql             ← Original file
-- Commit: a1b2c3d4                         ← Git commit hash
-- Message: Add user role column            ← Commit message (provides context)
-- Author: john.doe@example.com             ← Who made the change
-- Date: 2025-10-15 12:00:00                ← When it was committed
-- ============================================================

ALTER TABLE users ADD COLUMN default_role_id INT NULL;

-- Change 2/5, Change 3/5, etc...
```

### Where to Find Release Files

**GitHub Releases (Primary Location):**
1. Go to repository on GitHub
2. Click "Releases" (right sidebar or top navigation)
3. Find the release by environment and timestamp (e.g., "QA - 2025.10.15.1439")
4. View the 3 assets:
   - **Compiled SQL file** (e.g., `release-qa-2025.10.15.1439.sql`) - Download this for execution
   - **ZIP archive** (e.g., `release-qa-2025.10.15.1439-individual-files.zip`) - Download for reference
   - **Release notes** - Read for commit context

> **Note:** Releases are permanent (unlike GitHub Actions artifacts which expire after 90 days).

### What Makes It Different from Dev/QA/Prod

**Key Concept:** The release file contains ONLY the NEW changes that need to be applied.

**Example:**
```
Before promotion:
  dev branch: change1.sql, change2.sql, change3.sql (all applied to dev DB)
  qa branch: change1.sql (applied to qa DB)

After merging dev → qa:
  Release file: change2.sql, change3.sql (ONLY the new ones)
  qa branch: change1.sql, change2.sql, change3.sql (now matches dev)
```

Git automatically excludes changes that already exist in the target branch!

---

## Schema Folders

### auth/

**Database:** Authentication database

**Contains:**
- Authentication tables (user accounts, sessions)
- Authorization tables (roles, permissions, user groups)
- Audit trails
- User management

**Example Changes:**
```sql
-- Add role column
ALTER TABLE users ADD COLUMN default_role_id INT NULL;

-- Insert default roles
INSERT INTO role (name, description) VALUES ('admin', 'System administrator');

-- Create audit table
CREATE TABLE audit_log (
    id INT PRIMARY KEY AUTO_INCREMENT,
    user_id INT NOT NULL,
    action VARCHAR(100),
    timestamp DATETIME DEFAULT CURRENT_TIMESTAMP
);
```

---

### application/

**Database:** Application database

**Contains:**
- User data (app_users)
- Company data (companies)
- Text processing features
- Business logic tables
- Application data

**Example Changes:**
```sql
-- Add company index for performance
CREATE INDEX idx_user_company ON app_users(company_id);

-- Create text mapping table
CREATE TABLE text_mappings (
    id INT PRIMARY KEY AUTO_INCREMENT,
    original_term VARCHAR(255),
    mapped_term VARCHAR(255),
    confidence DECIMAL(5,2)
);
```

---

### integrations/

**Database:** Credentials database

**Contains:**
- Token definitions (api_tokens)
- Token attributes (token_attributes)
- Data sources (datasource)
- Metrics (datasource_metric)
- Dimensions (datasource_dimension)

**Example Changes:**
```sql
-- Add LLM context field to token attributes
ALTER TABLE token_attributes ADD COLUMN llm_context TEXT NULL;

-- Insert new data source metric
INSERT INTO datasource_metric (datasource_id, metric_display_name, metric_internal_name)
VALUES (1, 'Conversions', 'conversions');

-- Update token visibility
UPDATE api_tokens SET public = 1 WHERE internal_text_id IN ('METRIC', 'DIMENSION');
```

---

### tenants/

**Database:** Multiple client databases (each client has their own schema)

**Contains:**
- Changes that apply to multiple client schemas
- Client-specific data structures
- Campaign, keyword, ad group tables
- Performance data

**Example Changes:**
```sql
-- Add status field to campaign table (applies to all client schemas)
ALTER TABLE campaign ADD COLUMN status VARCHAR(50) DEFAULT 'active';

-- Add conversion tracking
ALTER TABLE keyword ADD COLUMN conversion_count INT DEFAULT 0;

-- Create index for performance
CREATE INDEX idx_campaign_status ON campaign(status);
```

> **Special Note:** Changes in this folder are typically executed against multiple client databases. The release file indicates this with "Schema: tenants" and the manager executing the change must apply it to all relevant client databases.

---

## Common Workflows

### Workflow 1: Emergency Hotfix

**Scenario:** Critical bug in production requires immediate database fix.

**Process:**

1. **Create hotfix branch:**
```bash
git checkout prod
git checkout -b hotfix-token-visibility
```

2. **Apply fix to prod database:**
```sql
-- Execute in prod database immediately
UPDATE api_tokens SET public = 1 WHERE internal_text_id = 'METRIC';
```

3. **Create SQL file and commit:**
```bash
# Create file
cat > integrations/20251015_1430_fix_token_visibility.sql << 'EOF'
-- Fix token visibility bug for METRIC token
UPDATE api_tokens SET public = 1 WHERE internal_text_id = 'METRIC';
EOF

# Commit to hotfix branch
git add integrations/20251015_1430_fix_token_visibility.sql
git commit -m "HOTFIX: Fix token visibility for METRIC token"
git push origin hotfix-token-visibility
```

4. **Download the compiled SQL (if needed for documentation):**
- Go to GitHub Releases
- Find the hotfix release
- Download the compiled SQL file
- The SQL has already been applied to prod, so this is just for documentation

5. **Merge hotfix back to main branches:**
```bash
# Merge to prod
git checkout prod
git merge hotfix-token-visibility
git push origin prod

# Merge to qa
git checkout qa
git merge hotfix-token-visibility
git push origin qa

# Merge to dev
git checkout dev
git merge hotfix-token-visibility
git push origin dev
```

> **Important:** Always merge hotfixes back to all branches to keep them in sync!

---

### Workflow 2: Rolling Back a Change

**Scenario:** A database change caused issues and needs to be reverted.

**Process:**

1. **Create rollback SQL file:**
```bash
# Example: Reverse the add_user_role_column change
cat > auth/20251015_1700_rollback_user_role_column.sql << 'EOF'
-- Rollback: Remove default_role_id column from users
ALTER TABLE users DROP FOREIGN KEY users_ibfk_1;
ALTER TABLE users DROP COLUMN default_role_id;
EOF
```

2. **Apply rollback to database:**
```sql
-- Execute in the affected database
ALTER TABLE users DROP FOREIGN KEY users_ibfk_1;
ALTER TABLE users DROP COLUMN default_role_id;
```

3. **Commit rollback file:**
```bash
git add auth/20251015_1700_rollback_user_role_column.sql
git commit -m "Rollback: Remove default_role_id column due to application issues"
git push origin dev
```

4. **Promote rollback through environments:**
- Follow normal promotion workflow (dev → qa → prod)
- Rollback SQL gets included in next release file

> **Note:** Not all database changes are reversible (e.g., data deletions, type conversions). Plan carefully and test in dev/qa before production.

---

### Workflow 3: Multiple Developers Working Simultaneously

**Scenario:** Two developers need to make database changes at the same time.

**Best Practice:**

**Developer 1:**
```bash
# Apply change to dev database
ALTER TABLE users ADD COLUMN last_login DATETIME NULL;

# Commit SQL file
git checkout dev
git pull origin dev  # Get latest changes first!
git add auth/add_last_login_column.sql
git commit -m "Add last_login tracking to users"
git push origin dev
```

**Developer 2:**
```bash
# Apply change to dev database
ALTER TABLE role ADD COLUMN priority INT DEFAULT 0;

# Commit SQL file
git checkout dev
git pull origin dev  # Pull Developer 1's change first!
git add auth/add_role_priority.sql
git commit -m "Add priority field to role table"
git push origin dev
```

**Key Points:**
- Always `git pull` before committing to get latest changes
- Each developer's change gets its own commit timestamp
- Release file will include both changes in correct order
- If both changes are in dev, they'll both be promoted to qa together

**What if there's a conflict?**
- Git will detect conflicting changes during pull/push
- Developers coordinate to resolve conflicts
- Both changes get applied to dev database in agreed order
- Commit SQL files in the order they were applied

---

### Workflow 4: What If Release File Fails?

**Scenario:** You execute the release file in QA and get an error.

**Process:**

1. **Stop immediately:**
   - Don't continue executing the rest of the file
   - Note which change caused the error

2. **Investigate the issue:**
   - Check the SQL syntax
   - Check for missing dependencies (e.g., table doesn't exist)
   - Check for data conflicts (e.g., foreign key constraint)

3. **Fix in dev database:**
   - Identify the problem change
   - Fix it in dev database
   - Create updated SQL file
   - Commit to dev branch

4. **Re-generate release file:**
   - Create new PR from dev to qa
   - Merge to trigger new release file generation
   - Download new release file

5. **Execute corrected release file:**
   - Start fresh or continue from where you stopped
   - Verify all changes apply successfully

**Example Error:**
```sql
-- Error executing this:
ALTER TABLE users ADD COLUMN default_role_id INT NOT NULL;

-- Error: Column cannot be NOT NULL without default value for existing rows

-- Fix: Make it nullable or provide default:
ALTER TABLE users ADD COLUMN default_role_id INT NULL;
```

---

## Important Rules & Best Practices

### Critical Rules

**1. ALWAYS Apply to Database Before Committing**

This is the most important rule. The branch state must match the database state.

```bash
# WRONG - don't do this!
git commit -m "Add column"  # Committed but not applied to database

# RIGHT - do this!
mysql> ALTER TABLE ...      # Apply to database FIRST
git commit -m "Add column"  # Then commit to Git
```

**2. Branch State = Database State**

If a SQL file exists in a branch, that change has been applied to the corresponding database.

```
dev branch files     = What's in dev database
qa branch files      = What's in qa database
prod branch files    = What's in prod database
```

**3. Never Skip Environments**

Always promote changes through environments in order:

```
✅ CORRECT: dev → qa → prod
❌ WRONG: dev → prod (skipped qa)
❌ WRONG: qa → dev (backwards)
```

**4. Never Force Push to QA/Prod**

Force pushing to qa/prod branches can cause loss of tracking and break the promotion workflow.

```bash
# WRONG - don't do this!
git push --force origin qa

# RIGHT - use normal merges
git merge dev
git push origin qa
```

**5. Test SQL Locally Before Committing**

Always test your SQL in dev database before committing to ensure it works.

**6. SQL Files Are Immutable Once Committed**

**CRITICAL:** Once a SQL file is committed and included in a release, it represents a permanent historical record and should NEVER be modified.

```bash
# WRONG - don't modify existing files!
# You create auth/create_users_table.sql, commit it, then later modify it
vim auth/create_users_table.sql  # Adding a column
git commit -m "Add email column"     # ❌ Modification won't be included in releases!

# RIGHT - create a new file for additional changes!
# Original file: auth/create_users_table.sql (creates users table)
# Later change: auth/add_users_email_column.sql (adds email column)
git add auth/add_users_email_column.sql
git commit -m "Add email column to users table"  # ✅ New file will be included
```

**Why This Rule Exists:**

The release workflow uses `git diff --diff-filter=A` which ONLY tracks files that were ADDED, not modified. This is intentional and enforces database changelog best practices:

1. **Immutability:** Each SQL file represents a point-in-time database change
2. **Order Tracking:** Files are ordered by their creation commit timestamp
3. **Historical Integrity:** Once released, a file is part of the permanent record
4. **Dependency Safety:** Prevents breaking execution order for dependent changes

**What Happens If You Modify a File:**
- The modification is IGNORED by the release workflow
- The original version stays in previous release history
- The modification won't appear in future releases
- Your changes won't be applied to other environments

**Real-World Example:**

```
Timeline:
1. Create auth/create_users_table.sql → Commit → Release includes it
2. Create auth/add_foreign_key.sql (references users) → Commit → Release includes it
3. Modify auth/create_users_table.sql (add email column) → Commit → ❌ IGNORED!
4. Next release: Only includes NEW files, not the modification

Result: QA/Prod never get the email column because the modification was ignored.

Correct Approach:
3. Create auth/add_users_email_column.sql → Commit → ✅ Included in next release
```

**Exception: Pre-Release Modifications**

You can modify a file if it hasn't been released yet:
- File created but not merged to qa/prod yet
- Still in dev branch only
- No release has been generated that includes it

Once a release includes the file, it becomes immutable.

---

### Best Practices

**1. Keep Changes Atomic**

One logical change per SQL file:
```bash
# GOOD
auth/add_user_role_column.sql         # Just the column
auth/insert_default_roles.sql         # Just the roles

# AVOID (unless truly related)
auth/user_role_complete_feature.sql   # Column + roles + indexes + data
```

**2. Use Descriptive Commit Messages**

```bash
# GOOD
git commit -m "Add default_role_id to users for authorization support"

# BAD
git commit -m "Update database"
```

**3. Test in Dev and QA Before Prod**

Never skip testing. Always follow the full promotion path:
- Test thoroughly in dev
- Test again in qa with production-like data
- Only then promote to prod

**4. Coordinate Breaking Changes**

If a database change breaks application code:
1. Coordinate with application developers
2. Plan deployment order (database before/after code)
3. Consider backward-compatible changes first
4. Document migration strategy

**5. Keep Release Files**

Save important release files outside of GitHub (artifacts expire after 90 days):
```bash
# Download and archive
mkdir -p ~/database-releases/2025-10-15/
mv release-prod-20251015.sql ~/database-releases/2025-10-15/
```

---

## FAQ / Troubleshooting

### What if I forgot to commit a database change?

**Problem:** You applied a change to dev database but forgot to commit the SQL file to Git.

**Solution:**
1. Create the SQL file with the change you applied
2. Commit it to dev branch with descriptive message
3. The commit timestamp will be "now" (not when you originally applied it)
4. The change will be included in the next promotion

**Example:**
```bash
# Oh no, I forgot to commit my change from yesterday!

# Create the SQL file now
cat > auth/add_user_status_column.sql << 'EOF'
ALTER TABLE users ADD COLUMN status VARCHAR(50) DEFAULT 'active';
EOF

# Commit it
git add auth/add_user_status_column.sql
git commit -m "Add status column to users (retroactive commit)"
git push origin dev
```

---

### What if the release file has an error?

**Problem:** Release file contains SQL that fails when executed.

**Solution:**
1. Stop executing the release file
2. Fix the problematic SQL in dev database
3. Create corrected SQL file
4. Commit to dev branch
5. Re-generate release file (merge dev → qa again)
6. Execute corrected release file

**Prevention:**
- Always test SQL thoroughly in dev before committing
- Review release files before executing
- Consider running against a qa restore first

---

### Can I skip a change?

**Problem:** Release file contains a change you don't want to apply.

**Solution:**

**Short answer:** You shouldn't skip changes. The system is designed for all changes to be promoted in order.

**If absolutely necessary:**
1. Manually execute all changes except the one you want to skip
2. Create a revert SQL file for the skipped change
3. Commit the revert to the target branch
4. This maintains branch = database state

**Better approach:**
- Revert the change in dev first
- Let the revert be promoted normally through environments

---

### How do I see what's different between environments?

**See what needs to be promoted from dev to qa:**
```bash
git diff qa..dev --name-only
```

**See what needs to be promoted from qa to prod:**
```bash
git diff prod..qa --name-only
```

**See detailed changes:**
```bash
git diff qa..dev
```

**See commits:**
```bash
git log qa..dev
```

---

### What if two people commit at the same time?

**Problem:** Two developers commit changes to dev at nearly the same time.

**Solution:**

The system handles this automatically:
1. Each commit gets its own timestamp
2. Git orders commits chronologically
3. Release file includes both changes in commit timestamp order
4. As long as changes don't conflict (different tables/columns), everything works fine

**If changes DO conflict:**
- Git will detect the conflict during merge/push
- Developers coordinate to resolve
- Apply changes to database in agreed order
- Commit SQL files in the same order

---

### What if I need to make a change directly in prod?

**Problem:** Emergency situation requires direct prod database change.

**Solution:**

**Use the hotfix workflow:**
1. Apply change to prod database (emergency!)
2. Create SQL file and commit to hotfix branch
3. Use manual release generation to document the change
4. **Important:** Merge hotfix back to dev/qa/prod branches to keep them in sync

**See [Workflow 1: Emergency Hotfix](#workflow-1-emergency-hotfix) for detailed steps.**

---

### What's the difference between the compiled SQL and the ZIP file?

**Answer:** The GitHub Release contains 3 assets with different purposes:

**1. Compiled SQL file** (e.g., `release-qa-2025.10.15.1439.sql`)
- **Purpose**: For execution
- **Use**: Download this, review it, and copy-paste into your database
- **Contains**: All changes merged into a single file in chronological order with metadata
- **This is the main file you need for deployment**

**2. ZIP archive** (e.g., `release-qa-2025.10.15.1439-individual-files.zip`)
- **Purpose**: For reference and audit trail
- **Use**: Download if you want to see individual SQL files as they were originally written
- **Contains**: All individual SQL files in their original folder structure (auth/, integrations/, etc.)
- **Useful for**: Understanding what changed in each file, auditing, debugging

**3. Release notes**
- **Purpose**: Provides context from commits
- **Use**: Read to understand what commits are included in this release
- **Contains**: Auto-generated list of commits with authors, dates, and messages
- **Useful for**: Deployment planning, understanding changes

**Which one should I use?**
- For deployment: Download the **compiled SQL file**
- For understanding changes: Read the **release notes**
- For detailed inspection: Download the **ZIP archive**

### How long do release files stay in GitHub?

**Answer:** GitHub Releases are permanent and don't expire.

**Note:**
- Releases (found in "Releases" tab) are permanent
- GitHub Actions artifacts (found in "Actions" tab) expire after 90 days
- This system uses Releases, so files don't expire

**Best Practice:**
- Still maintain backups of production release files
- Store in a secure location (shared drive, S3, etc.) for disaster recovery

---

### Can I use this system with multiple repositories?

**Answer:** This implementation uses a single repository for all database schemas.

**For multiple repositories:**
- Consider separate changelog repositories per project
- Or extend this system to support multiple repos
- Coordination between repos would be manual

---

## GitHub Actions Workflows

### 1. Generate Release File (Automatic)

**Trigger:** Merge to qa or prod branches

**What it does:**
1. Detects merge to qa or prod
2. Scans all schema folders for NEW changes
3. Orders changes chronologically by Git commit timestamp
4. Generates release file with metadata
5. Uploads as artifact

**How to view:**
1. Go to "Actions" tab
2. Click "Generate Release File" workflow
3. Click on latest run
4. Download artifact from "Artifacts" section

**Typical run time:** < 2 minutes

---

### 2. Manual Release Generation

**Trigger:** Manual workflow dispatch

**What it does:**
1. Prompts for parameters (branch, start date, end date)
2. Scans schema folders for changes in date range
3. Generates release file
4. Uploads as artifact

**How to use:**
1. Go to "Actions" tab
2. Click "Manual Release Generation" in left sidebar
3. Click "Run workflow" button (right side)
4. Fill in parameters:
   - Branch: Which branch to scan
   - Start date: Beginning of range (YYYY-MM-DD HH:MM:SS)
   - End date: End of range (YYYY-MM-DD HH:MM:SS)
5. Click "Run workflow"
6. Wait for completion
7. Download artifact

**Use cases:**
- Emergency hotfixes
- Partial deployments
- Historical release file generation
- Testing

---

### 3. SQL Naming Validation (Optional)

**Trigger:** Pull request creation/update

**What it does:**
1. Gets list of changed files from PR
2. Filters for SQL files in schema folders
3. Validates naming matches convention
4. Fails PR status check if non-compliant

**Note:** This workflow may or may not be enabled. Check with your team.

---

## Getting Help

**Questions?**
- Check this user guide first
- Check the [Database Changelog Spec](Database-Changelog-Spec.md) for technical details
- Ask your team lead or database administrator
- Reach out in team Slack channel

**Found a bug?**
- Open an issue in the repository
- Include details: what you did, what happened, what you expected
- Include relevant SQL files and error messages

**Want to suggest an improvement?**
- Open an issue with your suggestion
- Discuss with the team
- Submit a pull request if you've implemented it

---

## Summary

**Key Takeaways:**

1. **Branch = Database State** - If a SQL file exists in a branch, that change is in the database
2. **Apply Database First, Commit Second** - Always apply to database before committing to Git
3. **Use Schema Folders** - Put SQL files in correct folder (auth, application, integrations, tenants)
4. **Follow Promotion Path** - Always promote dev → qa → prod (never skip)
5. **GitHub Releases with 3 Assets** - Each release includes compiled SQL, ZIP archive, and release notes
6. **Compiled SQL for Execution** - Download the compiled SQL file and execute it (main deployment file)
7. **ZIP for Reference** - Download the ZIP archive if you need to see individual changes
8. **Release Notes for Context** - Read the auto-generated release notes to understand what changed
9. **Manual Release for Hotfixes** - Use manual workflow for emergency situations
10. **Chronological Order** - Git commit timestamps determine order in release files
11. **Test Before Production** - Always test in dev and qa before prod

**You're ready to use the database changelog system!**

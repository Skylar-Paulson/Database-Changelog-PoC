# SQL Syntax Validation Workflow Documentation

**Workflow File:** `.github/workflows/validate-sql-syntax.yml`

## Purpose

This workflow validates MySQL syntax for all SQL files in pull requests and direct commits, catching syntax errors before they reach release generation. It prevents broken SQL from being merged and deployed to databases.

## Why This Exists

**Problem Solved:**
- Developers may accidentally commit SQL with syntax errors
- Syntax errors aren't caught until release execution fails in database
- Manual review of every SQL file is time-consuming and error-prone
- Database execution failures cause deployment rollbacks and downtime
- No automated quality gate for SQL changes

**Solution Provided:**
- Automated syntax checking using real MySQL parser
- Immediate feedback on pull requests
- Blocks merges when syntax errors are present
- Detailed error messages for quick fixes
- Zero manual intervention required

## When It Triggers

### Trigger 1: Pull Requests

**Event:** Pull request opened, synchronized, or reopened

**Conditions:**
- Only when `.sql` files are changed
- Excludes `.github/` and `docs/` folders

**Example Scenarios:**
- Developer creates PR with new SQL files → Validation runs
- Developer pushes new commits to existing PR → Validation re-runs
- PR modifies existing SQL files → Validation runs on changed files

### Trigger 2: Direct Pushes

**Event:** Push to `dev`, `qa`, or `prod` branches

**Conditions:**
- Only when `.sql` files are changed
- Excludes `.github/` and `docs/` folders

**Example Scenarios:**
- Direct commit to dev branch → Validation runs
- Emergency hotfix pushed to prod → Validation runs

**Note:** While branch protection should prevent direct pushes to qa/prod, this provides a safety net.

## How It Works

### High-Level Process

1. **Detect Changed Files**: Identifies SQL files that changed in PR or commit
2. **Spin Up MySQL**: Starts MySQL 8.0 Docker container for validation
3. **Parse Each File**: Runs each SQL file through MySQL parser
4. **Collect Errors**: Captures syntax errors and line numbers
5. **Report Results**: Comments on PR (if failed) and sets workflow status

### Detailed Steps

#### Step 1: Detect Changed Files

**For Pull Requests:**
```bash
# Compare PR head against base branch
BASE_SHA="${{ github.event.pull_request.base.sha }}"
HEAD_SHA="${{ github.event.pull_request.head.sha }}"

git diff --name-only --diff-filter=d "$BASE_SHA"..."$HEAD_SHA" -- "*.sql"
```

**For Direct Pushes:**
```bash
# Compare current commit against previous
git diff --name-only --diff-filter=d HEAD~1 HEAD -- "*.sql"
```

**Filters Applied:**
- Only SQL files (`*.sql`)
- Only existing files (`--diff-filter=d` excludes deleted)
- Excludes `.github/` folder (workflow files)
- Excludes `docs/` folder (documentation)

#### Step 2: Spin Up MySQL

**Docker Service:**
```yaml
services:
  mysql:
    image: mysql:8.0
    env:
      MYSQL_ROOT_PASSWORD: test_password
      MYSQL_DATABASE: syntax_check
    options: >-
      --health-cmd="mysqladmin ping"
      --health-interval=10s
      --health-timeout=5s
      --health-retries=3
    ports:
      - 3306:3306
```

**Why MySQL 8.0:**
- Matches production environment
- Most strict parser (catches more errors)
- Latest MySQL syntax support
- Modern SQL features validated

**Health Checks:**
- Waits up to 30 seconds for MySQL to be ready
- Ensures database is available before validation
- Prevents false failures from container startup delays

#### Step 3: Parse Each File

**Validation Logic:**
```bash
for each SQL file:
  # Parse SQL through MySQL client
  mysql -h 127.0.0.1 -u root -ptest_password syntax_check < "$file" 2>&1

  # Check if output contains ERROR
  if ERROR found:
    Mark file as FAILED
    Capture error message
  else:
    Mark file as PASSED
```

**What It Catches:**
- ✅ Missing semicolons (sometimes)
- ✅ Invalid SQL keywords
- ✅ Syntax errors (typos, wrong order)
- ✅ Invalid column/table references (if tables don't exist)
- ✅ Type mismatches
- ✅ Constraint violations

**What It Doesn't Catch:**
- ❌ Logical errors (wrong business logic)
- ❌ Missing tables (if schema doesn't exist in test DB)
- ❌ Performance issues
- ❌ Security vulnerabilities (SQL injection)

#### Step 4: Collect Errors

**Error Capture:**
```bash
# Extract only ERROR lines from MySQL output
CLEAN_ERROR=$(echo "$ERROR_OUTPUT" | grep "ERROR" | head -5)

# Store for reporting
FAILED_FILES+=("$file")
ERROR_MESSAGES+=("$file: $CLEAN_ERROR")
```

**Example Error Output:**
```
ERROR 1064 (42000) at line 3: You have an error in your SQL syntax;
check the manual that corresponds to your MySQL server version for the
right syntax to use near 'SELCT * FROM users' at line 1
```

#### Step 5: Report Results

**On Success:**
- ✅ Green check mark in GitHub Actions
- ✅ Allows merge (if other checks pass)
- Simple success message in logs

**On Failure:**
- ❌ Red X in GitHub Actions
- ❌ Blocks merge (via required status check)
- Detailed error report

**PR Comment Format:**
```markdown
## ❌ SQL Syntax Validation Failed

The following SQL files have syntax errors:

### auth/add_user_table.sql
```
ERROR 1064 (42000) at line 5: You have an error in your SQL syntax;
check the manual that corresponds to your MySQL server version for the
right syntax to use near 'INTEGR' at line 1
```

### integrations/update_tokens.sql
```
ERROR 1064 (42000) at line 12: Unknown column 'expire_time' in 'field list'
```
```

## Validation Rules

### ✅ Valid SQL Examples

**Basic DDL:**
```sql
CREATE TABLE users (
    id INT PRIMARY KEY,
    name VARCHAR(255) NOT NULL
);
```

**ALTER TABLE:**
```sql
ALTER TABLE users
ADD COLUMN email VARCHAR(255);
```

**INSERT:**
```sql
INSERT INTO users (id, name) VALUES (1, 'John');
```

**Complex Query:**
```sql
CREATE INDEX idx_user_email ON users(email);

ALTER TABLE users
ADD CONSTRAINT fk_company
FOREIGN KEY (company_id) REFERENCES companies(id);
```

### ❌ Invalid SQL Examples

**Typo in Keyword:**
```sql
SELCT * FROM users;  -- ERROR: 'SELCT' should be 'SELECT'
```

**Missing Comma:**
```sql
CREATE TABLE users (
    id INT
    name VARCHAR(255)  -- ERROR: Missing comma after 'id INT'
);
```

**Wrong Order:**
```sql
ADD COLUMN email VARCHAR(255)
ALTER TABLE users;  -- ERROR: Wrong order
```

**Invalid Type:**
```sql
CREATE TABLE users (
    id INTEGR  -- ERROR: 'INTEGR' should be 'INTEGER' or 'INT'
);
```

## Required Status Check

To block merges when validation fails:

1. Go to repository Settings
2. Navigate to Branches
3. Select branch (e.g., `qa`)
4. Enable "Require status checks to pass"
5. Add "validate-sql" to required checks

**Result:** Pull requests with syntax errors cannot be merged.

## Excluded Files

The following files/folders are NOT validated:

- `.github/**` - Workflow files (not SQL for database)
- `docs/**` - Documentation files (even if named .sql)
- Non-.sql files (README, markdown, etc.)

## Edge Cases Handled

### No SQL Files Changed

**Behavior:** Workflow exits gracefully without validation

**Status:** Success (green check)

**Reason:** Nothing to validate

### Deleted SQL Files

**Behavior:** Deleted files are ignored (`--diff-filter=d`)

**Status:** Success (only validates existing files)

**Reason:** Can't validate non-existent files

### MySQL Startup Failure

**Behavior:** Workflow waits 30 seconds, then fails

**Error Message:** "MySQL failed to start within 30 seconds"

**Reason:** Container health checks ensure MySQL is ready

### Multiple Files, Some Fail

**Behavior:** Validates all files, reports all failures

**Status:** Failure (blocks merge)

**Comment:** Lists each failed file with its errors

## Performance Characteristics

- **Startup Time:** ~10-20 seconds (MySQL container + health checks)
- **Validation Time:** ~1-2 seconds per SQL file
- **Total Time:** Usually < 1 minute for typical PR
- **Scalability:** Can handle hundreds of SQL files
- **Resource Usage:** Minimal (uses GitHub Actions runner resources)

## Configuration Options

### Change MySQL Version

```yaml
services:
  mysql:
    image: mysql:8.0  # Change version here
```

**Options:** `mysql:5.7`, `mysql:8.0`, `mysql:8.4`, `mariadb:10.11`

### Change Trigger Branches

```yaml
on:
  push:
    branches:
      - dev
      - qa
      - prod
      - staging  # Add new branch
```

### Add More Excluded Paths

```yaml
paths:
  - '**.sql'
  - '!.github/**'
  - '!docs/**'
  - '!archive/**'  # Add exclusion
```

### Disable PR Comments

Remove this step to disable automatic PR comments:
```yaml
- name: Comment on PR (if validation failed)
  # Delete or comment out this entire step
```

## Integration with Other Workflows

### Generate Release Workflow

**Sequence:**
1. PR created with SQL files
2. Syntax validation runs ✅
3. PR approved and merged
4. Generate release workflow triggers
5. Release contains only valid SQL

**Benefit:** Release files never contain syntax errors

### Manual Release Workflow

**Sequence:**
1. Hotfix committed to branch
2. Syntax validation runs on push ✅
3. If validation passes, trigger manual release
4. Release generated with valid SQL

**Benefit:** Manual releases also validated

## Troubleshooting

### Validation Passes But SQL Fails in Database

**Possible Causes:**
1. Schema mismatch (tables exist in prod but not test DB)
2. Logical errors (syntax correct, logic wrong)
3. Permission issues (user doesn't have privileges)
4. Data-dependent issues (works on empty DB, fails with data)

**Solution:**
- Add schema setup to validation workflow
- Add integration tests
- Test in dev environment before promotion

### Validation Fails But SQL is Correct

**Possible Causes:**
1. MySQL version mismatch (using feature not in 8.0)
2. Database-specific syntax (PostgreSQL vs MySQL)
3. Missing database objects (tables, functions)

**Solution:**
- Verify SQL is MySQL-compatible
- Check MySQL version match
- Add schema setup if needed

### Validation Takes Too Long

**Possible Causes:**
1. Too many SQL files changed
2. Complex SQL with slow parsing
3. MySQL container slow to start

**Solution:**
- Reduce number of files in single PR
- Check MySQL container health
- Consider caching MySQL container (advanced)

### False Positives

**Scenario:** Validation reports error but SQL is valid

**Cause:** Missing database schema or objects

**Solution:** Add schema setup step:
```yaml
- name: Setup database schema
  run: |
    mysql -h 127.0.0.1 -u root -ptest_password syntax_check < schema.sql
```

## Security Considerations

### Test Database Credentials

**Current:** `root` / `test_password`

**Security:** ✅ Safe - ephemeral container destroyed after run

**Note:** Never use production integrations in CI/CD

### SQL Injection

**Scope:** This validates syntax, not security

**Limitation:** Does not detect SQL injection vulnerabilities

**Recommendation:** Use separate security scanning tools for that

### Permissions

```yaml
permissions:
  contents: read        # Read repository files
  pull-requests: write  # Add comments on PRs
```

**Minimal Permissions:** Only what's needed

## Benefits

1. **Catches Errors Early**: Before merge, not after deployment
2. **Immediate Feedback**: Developers see errors in seconds
3. **Prevents Downtime**: Broken SQL never reaches production
4. **Saves Time**: No rollbacks or emergency fixes
5. **Improves Quality**: Encourages developers to test SQL locally
6. **Zero Maintenance**: Fully automated, no manual review needed
7. **Blocks Bad Merges**: Required status check prevents merges
8. **Clear Error Messages**: Shows exactly what's wrong and where

## Limitations

### What It Doesn't Validate

- **Logical Correctness**: SQL syntax correct but logic wrong
- **Performance**: Query could be slow even if valid
- **Security**: SQL injection, privilege escalation
- **Idempotency**: Running script multiple times may fail
- **Dependencies**: Order of execution across files
- **Data Integrity**: Foreign key references, constraints (without schema)

### For Comprehensive Validation

Consider adding:
- Schema validation (check if tables/columns exist)
- Integration tests (test against real database)
- Performance testing (slow query detection)
- Security scanning (SQL injection detection)
- Idempotency testing (can run multiple times safely)

## Best Practices

### Writing SQL for Validation

✅ **Do:**
- Test SQL locally before committing
- Use standard MySQL syntax
- Include full table/column names
- Add IF NOT EXISTS for CREATE statements
- Document why validation might fail (missing schema)

❌ **Don't:**
- Use database-specific syntax (PostgreSQL, Oracle)
- Rely on specific data existing
- Use stored procedures without definitions
- Assume tables exist

### Example: Validation-Friendly SQL

```sql
-- Safe: Will validate even without schema
CREATE TABLE IF NOT EXISTS users (
    id INT AUTO_INCREMENT PRIMARY KEY,
    name VARCHAR(255) NOT NULL
);

-- Safe: Syntax correct, idempotent
ALTER TABLE users
ADD COLUMN IF NOT EXISTS email VARCHAR(255);

-- Risky: Assumes table exists (may fail validation)
-- But syntax is still validated
ALTER TABLE users ADD COLUMN email VARCHAR(255);
```

## Related Workflows

- **Generate Release** (`generate-release.yml`) - Benefits from validated SQL
- **Manual Release** (`manual-release.yml`) - Also benefits from validation

## Monitoring

### Check Validation Results

**Via GitHub UI:**
1. Go to Pull Requests
2. Look for ✅/❌ next to "validate-sql"
3. Click for details

**Via Actions Tab:**
1. Go to Actions
2. Select "Validate SQL Syntax" workflow
3. View recent runs and results

### Metrics to Track

- Validation failure rate (% of PRs with errors)
- Average validation time
- Common error types
- Time to fix after validation failure

## Screenshots

<img width="1080" height="977" alt="image" src="https://github.com/user-attachments/assets/08254352-7058-4b29-ba2e-c900745a6ee6" />

## Version History

- **Initial Version (2025-10-15)**: Basic syntax validation with MySQL 8.0
- **Added PR Comments (2025-10-15)**: Automatic error reporting on PRs

---

**Last Updated:** 2025-10-15
**Workflow Version:** 1.0
**Status:** Production Ready

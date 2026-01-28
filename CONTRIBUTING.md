# Contributing Guide

Thank you for your interest in contributing to this project!

## How to Contribute

### Reporting Issues

1. Check if the issue already exists
2. Create a new issue with:
   - Clear description of the problem
   - Steps to reproduce
   - Expected vs actual behavior
   - Environment details (OS, Docker version, PostgreSQL version)

### Submitting Changes

1. Fork the repository
2. Create a feature branch:
   ```bash
   git checkout -b feature/your-feature-name
   ```
3. Make your changes
4. Test locally:
   ```bash
   ./scripts/run-local.sh
   ```
5. Commit with clear message:
   ```bash
   git commit -m "feat: add new feature description"
   ```
6. Push and create a Pull Request

### Commit Message Format

We follow [Conventional Commits](https://www.conventionalcommits.org/):

```
<type>(<scope>): <description>

Examples:
feat(db): add user preferences table
fix(workflow): correct .NET version
docs: update README with troubleshooting
```

Types: `feat`, `fix`, `docs`, `style`, `refactor`, `test`, `chore`

## Development Setup

1. Clone the repository
2. Copy environment template:
   ```bash
   cp scripts/.env.example scripts/.env
   ```
3. Start local PostgreSQL:
   ```bash
   docker run -d --name postgres-local \
     -e POSTGRES_USER=postgres \
     -e POSTGRES_PASSWORD=postgres \
     -e POSTGRES_DB=sample_db \
     -p 5432:5432 \
     postgres:15
   ```
4. Run migrations:
   ```bash
   ./scripts/run-local.sh
   ```

## Code Style

### SQL Scripts

- Use `IF NOT EXISTS` / `IF EXISTS` for idempotency
- Add comments for non-obvious logic
- Use consistent naming (snake_case)
- Include version and description header

```sql
-- =============================================================================
-- Version: v0.XX
-- Description: Brief description of changes
-- =============================================================================
```

### Documentation

- Keep README.md focused and scannable
- Use tables for structured information
- Include code examples
- Update CHANGELOG.md for significant changes

## Questions?

Open a discussion or issue on GitHub.

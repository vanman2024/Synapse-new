# Session Archives

This directory contains archived activities from SESSION.md to prevent file bloat.

Archives are automatically created when SESSION.md grows beyond 300 lines, preserving older activity records while keeping the main SESSION.md file manageable.

## Archive Format

Each archive file is named according to the date when it was created:
```
session-YYYYMMDD.md
```

The contents include:
- A header with the archive date
- Sections for each activity period
- The same formatting as used in SESSION.md

## Accessing Archives

You can access archives in several ways:

1. **Browse directly**: Simply view the files in this directory. They are sorted by date, with the most recent archives appearing first in the file listing.

2. **List available archives**:
   ```bash
   ./scripts/workflow/session-archive.sh --list
   ```
   This will display all archived sessions with their dates and titles.

3. **Retrieve a specific archive**:
   ```bash
   ./scripts/workflow/session-archive.sh --retrieve=YYYYMMDD
   ```
   For example, to retrieve the March 12, 2025 session:
   ```bash
   ./scripts/workflow/session-archive.sh --retrieve=20250312
   ```

Archives are automatically created and managed by the session archiving system. You should not need to manually edit or manage these files.
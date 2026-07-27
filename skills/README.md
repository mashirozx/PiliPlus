# Local Fork Knowledge Base

This directory contains material owned by this fork. It is intentionally
separate from upstream application code so upstream rebases remain focused and
local maintenance knowledge stays discoverable.

## Directory Map

- `workflows/`: operational runbooks, including upstream synchronization.
- `architecture/`: long-lived subsystem notes and decisions.
- `changes/`: records of fork-specific changes, grouped by area when needed.
- `maintenance/`: rules for adding, updating, reviewing, and retiring records.

Create subdirectories when a category accumulates related records. Use concise,
descriptive kebab-case Markdown filenames. Prefer updating the existing record
when a change extends the same behavior; create a new record when it introduces
a separate feature, decision, or migration.
---
name: code-intel-rust
description: Focused Rust lookup after repo scoping, using AST queries first and LSP only when semantic precision is needed.
---

# Rust Code Intelligence

Use this after `repo-map` has already narrowed the search area.

This skill is for exact Rust navigation:

- locate a symbol in a likely file
- inspect imports or scope around a line
- resolve definitions, references, hover docs, diagnostics, or call hierarchy

## Workflow

1. Start with `repo-map` if the task is broad.
2. Use `ast ...` for fast structural lookups that do not require a daemon.
3. Escalate to `lsp ...` only when semantic precision matters.
4. Use `--repo-root` when running from a nested worktree or outside the target checkout.

## Commands

```bash
# Structural queries
code-intel-rust ast outline <file> [--json]
code-intel-rust ast symbols <file> [--json]
code-intel-rust ast imports <file> [--json]
code-intel-rust ast signature <file> <symbol> [--json]
code-intel-rust ast scope <file> <line> [col] [--json]
code-intel-rust ast search <pattern> [paths...] [--json]

# Semantic queries (requires flox service)
code-intel-rust lsp definition <file> <line> <col> [--json]
code-intel-rust lsp references <file> <line> <col> [--json]
code-intel-rust lsp hover <file> <line> <col> [--json]
code-intel-rust lsp diagnostics <file> [--json]
code-intel-rust lsp calls <file> <line> <col> [--direction in|out] [--json]
```

## Task Recipes

- Find the likely declaration in a candidate file: `ast signature`
- Explain the local construct around a line: `ast scope`
- Verify where a symbol resolves: `lsp definition`
- Find semantic usages after a repo-map pass: `lsp references`

## Handoff Acceptance

- When `repo-map` emits a `handoff`, inspect `primaryFile` first.
- Treat `recommendedCommand` as the default next step unless you already know a narrower AST query.
- Accept repo-relative paths directly; add `--repo-root` when the handoff came from another worktree or nested directory.
- Start with `ast outline`, `ast imports`, or `ast scope`.
- Escalate to `lsp` only after the AST pass has narrowed the exact symbol or position.

## Notes

- Human-readable output is the default.
- Add `--json` for compact machine-readable output.
- `ast search` requires `ast-grep`.
- `lsp ...` commands require `rust-analyzer` to be available.
- If LSP is unavailable, fall back to `ast` plus narrowed file selection from `repo-map`.

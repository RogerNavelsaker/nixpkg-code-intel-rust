# nixpkg-code-intel-rust

Rust code intelligence CLI with AST and LSP subcommands, packaged as a local Bun tool.

## Package

- Version: `0.1.0`
- Binary: `code-intel-rust`
- Entrypoint: `src/cli.ts`
- Description: Rust code intelligence CLI with AST and LSP subcommands

## What This Repo Does

- Packages the local Bun CLI with `bun2nix`
- Exposes the canonical `code-intel-rust` binary
- Keeps runtime code under `src/` and agent-facing guidance under `skills/`

Cross-tool flow:

```bash
repo-map query "**/*" --term agent --term scheduler --lang rs --json
code-intel-rust ast outline src/agent/scheduler.rs --repo-root /path/to/worktree
code-intel-rust lsp references src/agent/scheduler.rs 18 8 --repo-root /path/to/worktree
```

Use `repo-map` for discovery, then `code-intel-rust ast ...` for the first precise pass. Escalate to `lsp ...` when you need semantic definitions, references, hover, diagnostics, or call hierarchy.

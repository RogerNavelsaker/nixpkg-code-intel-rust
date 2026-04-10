#!/usr/bin/env bun
import { join } from "node:path";
import process from "node:process";

const [subcommand, ...rest] = process.argv.slice(2);

if (!subcommand) {
  console.error("usage: code-intel-rust <ast|lsp> ...");
  process.exit(1);
}

const entrypoints: Record<string, string> = {
  ast: "ast.ts",
  lsp: "lsp.ts",
};

const script = entrypoints[subcommand];

if (!script) {
  console.error(`unknown subcommand: ${subcommand}`);
  process.exit(1);
}

const proc = Bun.spawn([process.execPath, join(import.meta.dir, script), ...rest], {
  stdin: "inherit",
  stdout: "inherit",
  stderr: "inherit",
});

process.exit(await proc.exited);

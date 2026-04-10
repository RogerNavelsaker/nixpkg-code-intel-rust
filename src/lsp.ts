#!/usr/bin/env bun
import process from "node:process";
import { callLspService, commandExists, fail, parseCommonArgs, printOutput, scopedPort, serveLsp } from "./shared.ts";

const { args, json, repoRoot } = parseCommonArgs(process.argv.slice(2));

const config = {
  name: "rust-analyzer",
  command: ["rust-analyzer"],
  defaultPort: 33101,
  port: scopedPort(33101, repoRoot, process.env.RUST_CODE_INTEL_PORT),
  languageId: "rust",
  initializeOptions: {
    checkOnSave: false,
    cargo: { buildScripts: { enable: false } },
    procMacro: { enable: false },
  },
};

const [command, ...rest] = args;
if (!command) fail("usage", "Usage: bun lsp.ts <serve|definition|references|hover|diagnostics|calls> ...", json);

if (command === "serve") {
  if (!commandExists(config.command[0])) fail("missing_language_server", "rust-analyzer is not installed. Add it to flox and activate the environment.", json);
  await serveLsp(config, repoRoot);
  process.stdin.resume();
} else {
  const payload = toPayload(command, rest, json);
  const data = await callLspService(config, payload, json, repoRoot);
  printOutput(data, json);
}

function toPayload(command: string, rest: string[], json: boolean) {
  switch (command) {
    case "definition":
    case "references":
    case "hover":
      if (rest.length < 3) fail("usage", `Usage: bun lsp.ts ${command} <file> <line> <col>`, json);
      return { method: command, file: rest[0], line: Number(rest[1]), col: Number(rest[2]) };
    case "diagnostics":
      if (rest.length < 1) fail("usage", "Usage: bun lsp.ts diagnostics <file>", json);
      return { method: command, file: rest[0] };
    case "calls": {
      if (rest.length < 3) fail("usage", "Usage: bun lsp.ts calls <file> <line> <col> [--direction in|out]", json);
      const directionIndex = rest.indexOf("--direction");
      const direction = directionIndex >= 0 ? rest[directionIndex + 1] : "in";
      return { method: command, file: rest[0], line: Number(rest[1]), col: Number(rest[2]), direction };
    }
    default:
      fail("usage", `Unknown lsp command: ${command}`, json);
  }
}

#!/usr/bin/env node

import { spawn } from "node:child_process";
import { pathToFileURL } from "node:url";
import readline from "node:readline";

const [packageName, npxCommand, ...roots] = process.argv.slice(2);

if (!packageName || !npxCommand || roots.length === 0) {
  console.error("Usage: mcp-filesystem-proxy.mjs <package> <npx-command> <root> [...roots]");
  process.exit(2);
}

const child = spawn(npxCommand, ["--offline", "--yes", packageName, ...roots], {
  stdio: ["pipe", "pipe", process.stderr],
});

const parentInput = readline.createInterface({
  input: process.stdin,
  crlfDelay: Infinity,
});

parentInput.on("line", (line) => {
  if (line.trim().length > 0) {
    child.stdin.write(`${line}\n`);
  }
});

parentInput.on("close", () => child.stdin.end());

let outputBuffer = "";
child.stdout.on("data", (chunk) => {
  outputBuffer += chunk.toString();
  const lines = outputBuffer.split("\n");
  outputBuffer = lines.pop() ?? "";

  for (const line of lines) {
    forwardServerMessage(line.replace(/\r$/, ""));
  }
});

child.stdout.on("end", () => {
  if (outputBuffer.trim().length > 0) {
    forwardServerMessage(outputBuffer.trim());
  }
});

function forwardServerMessage(line) {
  if (line.trim().length === 0) {
    return;
  }

  let message;
  try {
    message = JSON.parse(line);
  } catch {
    console.error(`Ignoring invalid MCP child output: ${line}`);
    return;
  }

  if (message.method === "roots/list") {
    child.stdin.write(`${JSON.stringify({
      jsonrpc: "2.0",
      id: message.id,
      result: {
        roots: roots.map((root) => ({
          uri: pathToFileURL(root).href,
          name: root,
        })),
      },
    })}\n`);
    return;
  }

  if (message.method === "notifications/roots/list_changed") {
    return;
  }

  process.stdout.write(`${line}\n`);
}

for (const signal of ["SIGINT", "SIGTERM"]) {
  process.on(signal, () => {
    child.kill(signal);
    process.exitCode = 128 + (signal === "SIGINT" ? 2 : 15);
  });
}

child.on("error", (error) => {
  console.error(`Unable to start MCP filesystem server: ${error.message}`);
  process.exitCode = 1;
});

child.on("exit", (code, signal) => {
  if (signal) {
    process.kill(process.pid, signal);
  }
  process.exitCode = code ?? 1;
});

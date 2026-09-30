import { describe, expect, test } from "bun:test";
import { mkdtempSync, mkdirSync, rmSync, writeFileSync } from "node:fs";
import { tmpdir } from "node:os";
import { join } from "node:path";
import { pathToFileURL } from "node:url";
import { resolveToolDir } from "../src/bun/tool-dir";

describe("standalone tool directory", () => {
  test("honours the launcher override", () => {
    expect(resolveToolDir("file:///unrelated/index.js", "/my clone")).toBe("/my clone");
  });

  test("finds the clone from source and nested build output, including spaces", () => {
    const root = mkdtempSync(join(tmpdir(), "face swap "));
    try {
      writeFileSync(join(root, "face-swap.py"), "");
      writeFileSync(join(root, "package.json"), "{}");
      for (const relative of ["src/bun", "build/dev/Face Swap.app/Contents/Resources/app/bun"]) {
        const dir = join(root, relative);
        mkdirSync(dir, { recursive: true });
        expect(resolveToolDir(pathToFileURL(join(dir, "index.js")).href)).toBe(root);
      }
    } finally {
      rmSync(root, { recursive: true, force: true });
    }
  });

  test("reports a missing clone instead of selecting an arbitrary ancestor", () => {
    const root = mkdtempSync(join(tmpdir(), "face-swap-missing-"));
    try {
      expect(() => resolveToolDir(pathToFileURL(join(root, "index.js")).href)).toThrow("TOOL_DIR");
    } finally {
      rmSync(root, { recursive: true, force: true });
    }
  });
});

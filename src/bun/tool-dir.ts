import { existsSync } from "node:fs";
import { dirname, join } from "node:path";
import { fileURLToPath } from "node:url";

// Source and Electrobun build output have different depths. Find the clone by
// its files rather than assuming a fixed number of parent directories.
export function resolveToolDir(moduleUrl: string, override?: string): string {
  if (override) return override;
  let dir = dirname(fileURLToPath(moduleUrl));
  while (true) {
    if (existsSync(join(dir, "face-swap.py")) && existsSync(join(dir, "package.json"))) return dir;
    const parent = dirname(dir);
    if (parent === dir) throw new Error("Cannot find the face-swap clone. Set TOOL_DIR to its directory.");
    dir = parent;
  }
}

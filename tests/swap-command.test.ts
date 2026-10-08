import { describe, expect, test } from "bun:test";
import { mkdtempSync, rmSync } from "node:fs";
import { tmpdir } from "node:os";
import { join, resolve } from "node:path";
import { swapCommand } from "../src/bun/swap-command";

// A file name like "photo&calc&.jpg" is valid on Windows. cmd.exe would run
// everything after the & if the path were on its command line.
const hostile = "&echo INJECTED&";

function fixture() {
  const root = mkdtempSync(join(tmpdir(), "face-swap-spawn-"));
  return {
    root,
    paths: {
      target: join(root, `photo${hostile}.jpg`),
      source: join(root, `donor${hostile}.png`),
      output: join(root, `out${hostile}.png`),
      model: join(root, `missing${hostile}.onnx`),
    },
  };
}

describe("swap command", () => {
  test("keeps file paths off the cmd.exe command line", () => {
    const { root, paths } = fixture();
    try {
      const { cmd, env } = swapCommand("C:\\tools\\face-swap-runner.bat", paths);
      expect(cmd).toEqual(["cmd", "/c", "C:\\tools\\face-swap-runner.bat"]);
      expect(env).toEqual({
        FACE_SWAP_TARGET: paths.target,
        FACE_SWAP_SOURCE: paths.source,
        FACE_SWAP_OUTPUT: paths.output,
        FACE_SWAP_MODEL: paths.model,
      });
    } finally {
      rmSync(root, { recursive: true, force: true });
    }
  });

  // The model check runs before any heavy imports, so this needs no models or GPU.
  // On Windows python3 can be the Microsoft Store alias, so use python there.
  const python = process.platform === "win32" ? Bun.which("python") : (Bun.which("python3") ?? Bun.which("python"));
  test.skipIf(!python)("face-swap.py reads the paths from the environment", () => {
    const { root, paths } = fixture();
    try {
      const { env } = swapCommand("unused.bat", paths);
      const run = Bun.spawnSync([python!, resolve("face-swap.py")], { env: { ...process.env, ...env } });
      expect(run.stderr.toString()).toContain(`Model not found at: ${paths.model}`);
      expect(run.exitCode).toBe(1);

      const missing = Bun.spawnSync([python!, resolve("face-swap.py")], {
        env: { ...process.env, FACE_SWAP_TARGET: "", FACE_SWAP_SOURCE: "", FACE_SWAP_OUTPUT: "", FACE_SWAP_MODEL: "" },
      });
      expect(missing.stderr.toString()).toContain("--target, --source, --output");
      expect(missing.exitCode).toBe(2);
    } finally {
      rmSync(root, { recursive: true, force: true });
    }
  });

  test.skipIf(process.platform !== "win32" || !python)("the real runner does not run commands from file names", () => {
    const { root, paths } = fixture();
    try {
      const { cmd, env } = swapCommand(resolve("face-swap-runner.bat"), paths);
      const run = Bun.spawnSync(cmd, { env: { ...process.env, ...env } });
      expect(run.stdout.toString()).not.toContain("INJECTED");
      expect(run.stderr.toString()).toContain(`Model not found at: ${paths.model}`);
      expect(run.exitCode).toBe(1);
    } finally {
      rmSync(root, { recursive: true, force: true });
    }
  });
});

import { describe, expect, test } from "bun:test";
import { chmodSync, copyFileSync, existsSync, mkdirSync, mkdtempSync, readlinkSync, realpathSync, rmSync, writeFileSync } from "node:fs";
import { tmpdir } from "node:os";
import { join, resolve } from "node:path";

// These tests exercise the real shell scripts without launching a GUI or models.
describe.skipIf(process.platform === "win32")("POSIX installation and launch", () => {
  function fixture() {
    // macOS tmpdir is a symlink (/var -> /private/var) and the launcher resolves real paths.
    const root = realpathSync(mkdtempSync(join(tmpdir(), "face swap launch ")));
    const clone = join(root, "clone with spaces");
    const bin = join(root, "fake-bin");
    mkdirSync(clone);
    mkdirSync(bin);
    for (const name of ["face-swap", "install.sh"]) copyFileSync(resolve(name), join(clone, name));
    const bun = join(bin, "bun");
    writeFileSync(bun, '#!/bin/bash\nprintf "%s|%s|%s|%s|%s|%s|%s\\n" "$*" "$PWD" "$TOOL_DIR" "$FOLDER_PATH" "$TARGET_IMAGE" "$LOCAL_MARKER" "$PARENT_MARKER"\nif [[ "$*" == "run build:dev" ]]; then exit "${BUILD_EXIT:-0}"; fi\n');
    chmodSync(bun, 0o755);
    const env = { ...process.env, PATH: `${bin}:${process.env.PATH}`, LOCAL_MARKER: "", PARENT_MARKER: "", TARGET_IMAGE: "", FOLDER_PATH: "" };
    return { root, clone, env };
  }

  test("installed symlink loads only the clone env and forwards a target with spaces", () => {
    const { root, clone, env } = fixture();
    try {
      const destination = join(root, "command bin");
      const unrelated = join(root, "unrelated");
      mkdirSync(unrelated);
      const image = join(unrelated, "my photo.jpg");
      writeFileSync(image, "");
      mkdirSync(join(clone, "build"));
      writeFileSync(join(clone, ".env"), 'LOCAL_MARKER=from-clone\n');
      writeFileSync(join(root, ".env"), 'PARENT_MARKER=wrong-env\n');
      const install = Bun.spawnSync(["bash", join(clone, "install.sh"), destination, "--with-bun-install"], { env, cwd: unrelated });
      expect(install.exitCode).toBe(0);
      expect(readlinkSync(join(destination, "face-swap"))).toBe(join(clone, "face-swap"));
      // Installing again must remain safe.
      expect(Bun.spawnSync(["bash", join(clone, "install.sh"), destination], { env }).exitCode).toBe(0);
      const launch = Bun.spawnSync([join(destination, "face-swap"), image], { env, cwd: unrelated });
      expect(launch.exitCode).toBe(0);
      expect(launch.stdout.toString().trim()).toBe(`run dev|${clone}|${clone}|${unrelated}|${image}|from-clone|`);
    } finally { rmSync(root, { recursive: true, force: true }); }
  });

  test("first-run build failure stops before opening the GUI", () => {
    const { root, clone, env } = fixture();
    try {
      const launch = Bun.spawnSync(["bash", join(clone, "face-swap")], { env: { ...env, BUILD_EXIT: "7" } });
      expect(launch.exitCode).toBe(7);
      expect(launch.stdout.toString()).toContain("run build:dev|");
      expect(launch.stdout.toString()).not.toContain("run dev|");
    } finally { rmSync(root, { recursive: true, force: true }); }
  });

  test("folder launch and invalid arguments", () => {
    const { root, clone, env } = fixture();
    try {
      mkdirSync(join(clone, "build"));
      const launch = Bun.spawnSync(["bash", join(clone, "face-swap"), root], { env });
      expect(launch.exitCode).toBe(0);
      expect(launch.stdout.toString().trim()).toBe(`run dev|${clone}|${clone}|${root}|||`);
      expect(Bun.spawnSync(["bash", join(clone, "face-swap"), join(root, "missing")], { env }).exitCode).toBe(1);
      const destination = join(root, "not-created");
      expect(Bun.spawnSync(["bash", join(clone, "install.sh"), destination, "--bad"], { env }).exitCode).toBe(1);
      expect(existsSync(destination)).toBe(false);
    } finally { rmSync(root, { recursive: true, force: true }); }
  });
});

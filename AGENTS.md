# Agent guidance for face-swap

Face Swap is a Windows desktop tool using Electrobun, Bun, React/TypeScript and a
Python InsightFace worker. There is also a POSIX development launcher, but the
backend currently requires Windows cmd.exe. Do not claim macOS swapping works.

## Working rules

- Use test-first development for non-trivial changes. Extract a clean test seam
  first if needed, then implement until the test passes.
- After changing behaviour, expectations, UI, persistence or startup, update and
  rerun the relevant tests. Run `bun test` and `bun run typecheck` before committing.
- Run `bun run build:dev` to check the Electrobun build. On Windows, smoke-test
  `wscript.exe .\face-swap.vbs` and check exit codes. Local tests never need models,
  a GPU or paid services.
- Parse every PowerShell script with
  `[System.Management.Automation.Language.Parser]::ParseFile` before committing.
  Run installer/uninstaller integration checks on Windows, including preservation
  of other tools' Explorer verbs.
- GUI shortcuts must launch via `face-swap.vbs`, with window style 0. Do not
  introduce console flashes, including on a first-run build.
- Keep batch files ASCII. Write generated stubs with `-Encoding ASCII`.
- Source stays in this clone. `C:\dev\tools` contains generated stubs and optional
  large binaries only. Never commit EXE/DLL files or model weights. If adding a
  batch command that needs a large binary there, accept `EXEDIR` and fall back to
  `%~dp0` when it is unset.
- `deps.ps1` must remain self-contained, idempotent and clear about missing
  dependencies. Check imports before pip installs and use colour for progress.
  Large manually downloaded binaries should get instructions, not auto-downloads.
- `install.ps1` runs this repo's `deps.ps1`; `-SkipDeps` skips dependency setup.
  Re-run installation after moving the clone or changing generated entries.
  Ordinary edits use the live clone through the existing stubs.
- Keep the shared "Mike's Tools" submenu. Change only `FaceSwap` verbs, and never
  delete another tool's entries or the shared root during uninstall.
- `.env` belongs at this repo's root. No API keys are needed. Preserve existing
  `%LOCALAPPDATA%\face-swap` model/log/session paths.
- Keep README language plain and personal, with no em or en dashes. UI designs
  should avoid eyebrows and kickers. PR descriptions start with `## Why`.

## Key files

- `src/bun/index.ts`: window, local HTTP/SSE server and swap jobs.
- `src/bun/tool-dir.ts`: clone lookup for source and built entry points.
- `src/ui/App.tsx`: target/source selection, logs and result preview.
- `face-swap.py`: face detection, swaps and video processing.
- `face-swap-runner.bat`: Windows Python alias resolution through cmd.exe.
- `face-swap.vbs`: silent Windows GUI launcher; `face-swap`: POSIX dev launcher.
- `install.ps1`, `uninstall.ps1`, `install-lib.ps1`: Windows integration.
- `install.sh`: symlink the POSIX launcher into `~/.local/bin`.

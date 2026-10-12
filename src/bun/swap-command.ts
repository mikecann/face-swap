import { win32 } from "node:path";

export type SwapPaths = { target: string; source: string; output: string; model: string };

// cmd.exe reads its whole command line as a script, so a file name or clone
// directory with & | ^ in it would run commands. Keep the command line fixed:
// run the runner by name from its own directory.
export function runnerCommand(runnerBat: string, args: string[] = []) {
  return {
    cmd: ["cmd", "/c", `.\\${win32.basename(runnerBat)}`, ...args],
    cwd: win32.dirname(runnerBat),
  };
}

// The swap paths go to face-swap.py through the environment, never cmd.exe.
export function swapCommand(runnerBat: string, paths: SwapPaths) {
  return {
    ...runnerCommand(runnerBat),
    env: {
      FACE_SWAP_TARGET: paths.target,
      FACE_SWAP_SOURCE: paths.source,
      FACE_SWAP_OUTPUT: paths.output,
      FACE_SWAP_MODEL: paths.model,
    },
  };
}

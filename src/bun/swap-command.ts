export type SwapPaths = { target: string; source: string; output: string; model: string };

// cmd.exe reads its whole command line as a script, so a file name with & | ^
// in it would run commands. Keep the command line fixed and hand the paths to
// face-swap.py through the environment instead.
export function swapCommand(runnerBat: string, paths: SwapPaths) {
  return {
    cmd: ["cmd", "/c", runnerBat],
    env: {
      FACE_SWAP_TARGET: paths.target,
      FACE_SWAP_SOURCE: paths.source,
      FACE_SWAP_OUTPUT: paths.output,
      FACE_SWAP_MODEL: paths.model,
    },
  };
}

# leetcodeOS

iPhone terminal + LeetCode daily practice.

- **Terminal** — full terminal on your phone (Termius-style host list). Connects over Tailscale to any ttyd web terminal; ships pointed at slyterm on the Mac (`:7681`).
- **LeetCode** — daily challenge card (difficulty, acceptance, tags) and your public solve stats by username. No LeetCode login needed.
- **Solve in Terminal** — jumps from the daily problem straight into the terminal.

## Build

XcodeGen project — `project.yml` is the source of truth. CI (`.github/workflows/ci.yml`) does an unsigned compile check, then archives with cloud-managed signing and uploads to TestFlight on every push to main.

```sh
xcodegen generate
open LeetcodeOS.xcodeproj
```

Requires Tailscale on the phone for the terminal tab.

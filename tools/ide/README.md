# Safe JetBrains Move Helpers

These helpers are intended for Cascade workflows that need to move a file while preserving usages/imports through the native JetBrains refactoring engine.

Supported IDEs:

- Rider
- GoLand
- IntelliJ IDEA
- WebStorm

The helper never calls `mv` or `git mv`. With `--apply`, it opens the source file, activates the native JetBrains `Refactor → Move` action through the `F6` shortcut, copies the destination directory to the clipboard, and waits for the user to review and confirm `Update Usages` in the IDE. It then verifies the expected path and runs `git diff --check`. When Cascade invokes it without an interactive stdin, it waits automatically for the expected destination instead of reading from the terminal.

## Usage

Dry run:

```bash
tools/ide/safe-move-goland.sh \
  --source internal/party/application/party_creator.go \
  --destination internal/party/application/creator/party_creator.go
```

Apply the native IDE refactor and run verification:

```bash
tools/ide/safe-move-goland.sh \
  --source internal/party/application/party_creator.go \
  --destination internal/party/application/creator/party_creator.go \
  --apply \
  --timeout-seconds 180 \
  --verify-command 'go test ./...'
```

Use the corresponding wrapper for Rider, IntelliJ IDEA, or WebStorm. The source and destination must be inside the same Git project, the destination directory must already exist, and the filename must remain unchanged. Use the IDE's separate Rename refactor when the filename also changes.

## Cascade/IDE requirement

The terminal process running the script must have macOS Accessibility permission for System Events, and the selected IDE must be openable by its application name. Cascade may run the script in Auto/Turbo mode, but the user must still review and confirm the native IDE preview. If UI automation is unavailable, run the IDE's `Refactor → Move` action manually; do not replace it with `mv` or `git mv`.

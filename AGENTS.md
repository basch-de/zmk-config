# Repository instructions

## Repository scope

- User keyboard configuration belongs under `config/`.
- Files under `boards/` are the imported hardware definitions. Treat them as
  read-only unless the requested task explicitly requires a board-level
  change.
- Do not modify stock keymaps under `boards/` during ordinary user-keymap
  work.
- Do not push changes or trigger GitHub Actions unless explicitly requested.

## Keyboard scope

- Every keyboard task must have exactly one explicit target keyboard.
- Treat the selected target as chat-local scope. Do not infer it from another
  chat, a repository default, or the currently active editor tab.
- Keep the selected target unchanged for the chat unless the user explicitly
  redefines the scope.
- Only files belonging to the target keyboard may be modified. Files for
  other keyboards are read-only references.
- If the target keyboard is ambiguous, ask before modifying keyboard files.
- A change that affects more than one keyboard requires an explicit request
  from the user.
- Shared files such as `AGENTS.md`, `build.yaml`, `config/west.yml`, and files
  under `tools/` may only be changed when the request includes the shared
  concern or the shared change is required to complete the requested task.

## Firmware and build configuration

- `config/west.yml` pins the ZMK version and must only be updated when
  explicitly requested.
- `build.yaml` defines the GitHub Actions build matrix.
- Board-level changes must consider both the left and right variants of the
  target keyboard.
- Preserve the normal firmware and `settings_reset` build entries unless
  their removal is explicitly requested.
- Do not expect or attempt a local ZMK firmware build.
- Multiple firmware or keymap changes may be accumulated before the user
  starts a GitHub Actions build.
- Only report a successful ZMK firmware build after all relevant GitHub
  Actions jobs for the changed configuration have completed successfully.

## Verification

- Every change must pass `git diff --check`.
- Follow the more specific verification instructions in nested `AGENTS.md`
  files for files within their directory scope.
- Firmware, board, `.conf`, and keymap changes are ultimately build-verified
  by GitHub Actions when the user decides to trigger a build.

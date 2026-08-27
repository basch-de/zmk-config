# Repository instructions

## Repository-wide rules

- `config/sofle_choc_pro.keymap` is the active user keymap.
- `boards/arm/sofle_choc_pro/sofle_choc_pro.keymap` is the stock board
  keymap and must only be changed when explicitly requested.
- Do not push changes or trigger GitHub Actions unless explicitly requested.

## Sofle keymap (`config/sofle_choc_pro.keymap`)

### Layers and physical positions

- Prefer named layer defines such as `NUM`, `NAV`, and `WINDOW` instead of
  numeric layer references.
- Layer define values must match the layer order inside the `keymap` node,
  starting with layer 0.
- Every active layer must have a `display-name`.
- Use `display-name` instead of the deprecated Devicetree `label` property
  for keymap layers and custom behaviors.
- The Sofle keymap currently contains five active layers and 60 physical
  keys per layer.
- Preserve binding order and physical key positions unless the requested
  change explicitly alters the layout.
- When adding or removing a layer or physical key, also update the PDF
  generator, its validation, and its page layout.

### Layout design invariants

- The `NUM` layer intentionally combines one-handed navigation on the left
  half with a number pad on the right half.
- Use regular number keycodes (`N0`–`N9`) on the `NUM` layer instead of
  keypad keycodes so number entry remains independent of Num Lock.
- Preserve transparent bindings at the `NUM` and `NAV` thumb positions that
  allow the conditional `ADJUST` layer to activate while both layers are
  held.
- Preserve the matching `&tog NUM` bindings on the `WINDOW` and `NUM`
  layers; they provide the lock and unlock path for the `NUM` layer.
- Preserve the one-handed editing row on `Z`, `X`, `C`, `V`, and `B` in the
  `NUM` and `NAV` layers: undo, cut, copy, paste, and Space.
- On the `ADJUST` layer, preserve the mirrored reset and bootloader
  positions: reset on the outer keys and bootloader on the adjacent inner
  keys.

### Matrix formatting

After every modification to `config/sofle_choc_pro.keymap`, format every
active and commented-out `bindings = < ... >` block according to the
physical Sofle matrix described below.

Treat every layer as 14 logical columns:

- Rows 1–3 contain 12 bindings:
  - columns 1–6: left half
  - columns 7–8: empty
  - columns 9–14: right half
- Row 4 contains 14 bindings:
  - columns 1–6: left half
  - columns 7–8: inner keys
  - columns 9–14: right half
- The thumb row contains 10 bindings:
  - columns 1–2: empty
  - columns 3–7: left thumb keys
  - columns 8–12: right thumb keys
  - columns 13–14: empty

Visual representation:

```text
01 02 03 04 05 06       09 10 11 12 13 14
01 02 03 04 05 06       09 10 11 12 13 14
01 02 03 04 05 06       09 10 11 12 13 14
01 02 03 04 05 06 07 08 09 10 11 12 13 14
      03 04 05 06 07 08 09 10 11 12
```

#### Alignment rules

- Format each layer independently.
- Every `&` assigned to the same logical column must start at exactly the
  same character position within that layer.
- A complete ZMK binding, including its parameters and nested expressions,
  is one indivisible matrix cell.
- Determine each logical column's width from the longest binding occupying
  that column, followed by at least two spaces.
- Empty logical columns must still occupy their calculated horizontal space.
- Use spaces as needed for matrix-cell padding; this padding is independent
  of the four-space structural indentation.
- Preserve the existing five-row structure.
- Do not use another layer as a formatting template.
- Never change bindings, arguments, ordering, comments, or behavior merely
  to achieve alignment.

### Whitespace and indentation

- In `config/sofle_choc_pro.keymap`, use four spaces per structural
  indentation level and never use tabs.
- Inside `bindings = < ... >` matrices, use additional spaces as needed to
  align logical columns.
- Matrix alignment spaces do not need to be multiples of four.
- Do not change binding contents merely to satisfy indentation or alignment.

### Hardware constraints

- This keyboard has no physical rotary encoders installed.
- Keep the existing EC11/encoder firmware configuration unless its removal
  is explicitly requested and the resulting GitHub Actions firmware build
  is verified.

## Keymap PDF tool (`tools/keymap-pdf/`)

### Inputs and outputs

- `config/sofle_choc_pro.json` is the physical-layout source for the PDF
  generator and must only be changed when the physical geometry changes.
- The `sensors[].label` fields in the JSON file are metadata and do not
  indicate that physical encoders are installed.
- Generated PDFs belong under `output/pdf/`.
- Preview images and caches belong under `tmp/keymap-pdf/`.
- Keep the Swift module cache under `tmp/keymap-pdf/` between runs to speed
  up subsequent PDF generation.
- Do not commit generated files from `output/` or `tmp/`.

### Generator behavior

- Review every generator warning. Unknown keys or behaviors may require a
  label, color category, or activation parser update.
- Layer activation descriptions must be derived from the keymap and must
  not be hard-coded.
- Layer behaviors must use the dedicated layer color.
- Valid ZMK syntax takes precedence over limitations of the PDF parser.
- If the generator cannot parse a valid keymap construct, improve the
  generator instead of rewriting valid keymap syntax solely for the parser.
- `./tools/keymap-pdf/generate.sh` is the authoritative entry point for PDF
  generation and validation.
- The generator uses the existing macOS Swift toolchain and requires no
  project-local dependency installation. If the required toolchain or
  frameworks are unavailable, do not report the PDF as generated or
  visually verified.
- Do not install dependencies or add alternative PDF tooling solely to
  generate or validate the keymap PDF.

### Visual validation

- Inspect both generated preview pages for clipping, overlaps, unreadable
  text, and incorrect physical-key placement.
- After parser changes, verify that the current keymap produces no
  unexpected warnings.

## Firmware and build configuration

- `config/west.yml` pins the ZMK version and must only be updated when
  explicitly requested.
- `build.yaml` defines the GitHub Actions build matrix.
- Board-level changes must consider both the left and right Sofle variants.
- Preserve the normal firmware and `settings_reset` build entries unless
  their removal is explicitly requested.
- Do not expect or attempt a local ZMK firmware build.
- Multiple firmware or keymap changes may be accumulated before the user
  starts a GitHub Actions build.
- Only report a successful ZMK firmware build after all relevant GitHub
  Actions jobs for the changed configuration have completed successfully.

## Verification by change type

- Every change: run `git diff --check`.
- Keymap changes: verify the matrix formatting, run
  `./tools/keymap-pdf/generate.sh`, and visually inspect both preview pages.
- PDF generator changes: run `./tools/keymap-pdf/generate.sh`, check for
  unexpected warnings, and visually inspect both preview pages.
- Firmware, board, `.conf`, and keymap changes are ultimately build-verified
  by GitHub Actions when the user decides to trigger a build.

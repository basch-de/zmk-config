# Repository instructions

## Project source of truth

- `config/sofle_choc_pro.keymap` is the active user keymap.
- `boards/arm/sofle_choc_pro/sofle_choc_pro.keymap` is the stock board
  keymap and must only be changed when explicitly requested.
- Prefer named layer defines such as `NUM`, `NAV`, and `WINDOW` instead of
  numeric layer references.

## Sofle keymap matrix formatting

After every modification to `config/sofle_choc_pro.keymap`, format every
active and commented-out `bindings = < ... >` block according to the
physical Sofle matrix described below.

### Logical matrix

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

### Alignment rules

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
- After editing, run `git diff --check`.

## Whitespace and indentation

- Use four spaces per structural indentation level.
- Never use tabs anywhere in the file.
- Inside `bindings = < ... >` matrices, use additional spaces as needed to
  align logical columns.
- Matrix alignment spaces do not need to be multiples of four.
- Do not change binding contents merely to satisfy indentation or alignment.

## Keymap and hardware constraints

- The Sofle keymap currently contains five active layers and 60 physical
  keys per layer.
- When adding or removing a layer or physical key, also update the PDF
  generator, its validation, and its page layout.
- Preserve binding order and physical key positions unless the requested
  change explicitly alters the layout.
- This keyboard has no physical rotary encoders installed.
- Keep the existing EC11/encoder firmware configuration unless its removal
  is explicitly requested and the resulting firmware build is verified.

## PDF generator

- The PDF generator is located under `tools/keymap-pdf/`.
- After changing the Sofle keymap or PDF generator, run
  `./tools/keymap-pdf/generate.sh`.
- Review every generator warning. Unknown keys or behaviors may require a
  label, color category, or activation parser update.
- Layer activation descriptions must be derived from the keymap and must
  not be hard-coded.
- Layer behaviors must use the dedicated layer color.
- Inspect both generated preview pages for clipping, overlaps, unreadable
  text, and incorrect physical-key placement.
- Generated PDFs belong under `output/pdf/`.
- Preview images and caches belong under `tmp/keymap-pdf/`.
- Do not commit generated files from `output/` or `tmp/`.
- The current Swift generator requires macOS frameworks. If they are not
  available, do not report the PDF as generated or visually verified.

## Verification

After relevant changes:

1. Run `git diff --check`.
2. Run `./tools/keymap-pdf/generate.sh` after keymap or generator changes.
3. Run a ZMK firmware build after keymap, board, or `.conf` changes when the
   build environment is available.
4. Do not report a successful build unless it was actually executed.

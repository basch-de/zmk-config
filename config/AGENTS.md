# User keyboard configuration instructions

These instructions apply to files under `config/` in addition to the
repository-wide instructions in the root `AGENTS.md`.

## Keyboard ownership

- `sofle_choc_pro.keymap`, `sofle_choc_pro.conf`, and
  `sofle_choc_pro.json` belong to the Sofle Choc Pro.
- `corne_choc_pro.keymap`, `corne_choc_pro.conf`, and
  `corne_choc_pro.json` belong to the Corne Choc Pro.
- `piantor_pro_bt.keymap`, `piantor_pro_bt.conf`, and
  `piantor_pro_bt.json` belong to the Piantor Pro BT.
- Do not modify files belonging to a keyboard other than the target keyboard.
- Another keyboard's files may be inspected as a reference, but physical
  positions, trigger lists, key counts, and layer numbers must not be copied
  without recalculating them for the target keyboard.

## Shared keymap conventions

- Prefer named layer defines such as `NUM`, `NAV`, and `WINDOW` instead of
  numeric layer references.
- Layer define values must match the layer order inside the `keymap` node,
  starting with layer 0.
- Every active layer must have a `display-name`.
- Use `display-name` instead of the deprecated Devicetree `label` property
  for keymap layers and custom behaviors.
- Preserve binding order and physical key positions unless the requested
  change explicitly alters the layout.
- Use four spaces per structural indentation level and never use tabs in
  user keymaps.
- Inside `bindings = < ... >` matrices, use additional spaces as needed to
  align logical columns. Matrix alignment spaces do not need to be multiples
  of four.
- Never change binding contents merely to satisfy indentation or alignment.
- When adding or removing a layer or physical key, also update any PDF
  generator validation and page layout that supports the target keyboard.

### Matrix alignment

- After every keymap modification, format every active and commented-out
  `bindings = < ... >` block according to the target keyboard's physical
  matrix.
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
- Do not use another layer as a formatting template.
- Never change bindings, arguments, ordering, comments, or behavior merely
  to achieve alignment.

## Sofle Choc Pro (`sofle_choc_pro.keymap`)

### Layers and physical positions

- This is the active Sofle user keymap.
- The keymap contains five active layers and 60 physical keys per layer.

### Layout design invariants

- The `NUM` layer intentionally combines one-handed navigation on the left
  half with a number pad on the right half.
- Use regular number keycodes (`N0`-`N9`) on the `NUM` layer instead of keypad
  keycodes so number entry remains independent of Num Lock.
- Do not add automatic activation for the `SYS` layer; it must not use a
  `conditional_layers` rule.
- Preserve the separate positional home-row-mod behaviors `hml` and `hmr`.
  Each behavior is triggered by the opposite keyboard half plus the six used
  middle thumb positions 52-57. The four outer physical thumb positions 50,
  51, 58, and 59 remain excluded.
- Preserve the matching `&tog NUM` bindings on the `WINDOW` and `NUM` layers;
  they provide the lock and unlock path for the `NUM` layer.
- Preserve the one-handed editing row on `Z`, `X`, `C`, `V`, and `B` in the
  `NUM` and `NAV` layers: undo, cut, copy, paste, and Space.
- On the `SYS` layer, preserve the mirrored reset and bootloader positions:
  reset on the outer keys and bootloader on the adjacent inner keys.

### Matrix formatting

After every modification to `sofle_choc_pro.keymap`, format every active and
commented-out `bindings = < ... >` block according to the physical Sofle
matrix described below.

Treat every layer as 14 logical columns:

- Rows 1-3 contain 12 bindings:
  - columns 1-6: left half
  - columns 7-8: empty
  - columns 9-14: right half
- Row 4 contains 14 bindings:
  - columns 1-6: left half
  - columns 7-8: inner keys
  - columns 9-14: right half
- The thumb row contains 10 bindings:
  - columns 1-2: empty
  - columns 3-7: left thumb keys
  - columns 8-12: right thumb keys
  - columns 13-14: empty

Visual representation:

```text
01 02 03 04 05 06       09 10 11 12 13 14
01 02 03 04 05 06       09 10 11 12 13 14
01 02 03 04 05 06       09 10 11 12 13 14
01 02 03 04 05 06 07 08 09 10 11 12 13 14
      03 04 05 06 07 08 09 10 11 12
```

- Preserve the existing five-row structure.

### Hardware constraints

- This keyboard has no physical rotary encoders installed.
- Keep the existing EC11/encoder firmware configuration unless its removal
  is explicitly requested and the resulting GitHub Actions firmware build is
  verified.
- The `sensors[].label` fields in `sofle_choc_pro.json` are metadata and do
  not indicate that physical encoders are installed.

### Verification

- Verify all binding matrices against the Sofle matrix rules.
- Run `../tools/keymap-pdf/generate.sh` from this directory, or
  `./tools/keymap-pdf/generate.sh` from the repository root.
- Review all generator warnings and visually inspect both generated preview
  pages.

## Corne Choc Pro (`corne_choc_pro.keymap`)

### Preparation status

- This is the active Corne user keymap, but it has not yet been migrated to
  the current Sofle layout design.
- The current Corne board definition and physical-layout JSON expose 46 key
  positions: 14 in each of rows 1 and 2, 12 in row 3, and six thumb keys.
- Do not assume that the arriving physical keyboard uses all 46 positions.
  Confirm whether it is the 42-key or 46-key variant before changing the key
  count, position map, or physical-layout JSON.
- The existing nine-layer Corne keymap is a starting point, not a design
  invariant.
- Do not migrate the Sofle keymap wholesale. Transfer behaviors and layer
  concepts deliberately and recalculate all Corne position lists.
- Keep the Sofle configuration read-only while the Corne is the target
  keyboard.

### Current 46-position matrix

Until the hardware variant is confirmed, preserve the current Corne binding
shape:

- Rows 1-2 contain 14 bindings in logical columns 1-14.
- Row 3 contains 12 bindings in columns 1-6 and 9-14.
- The thumb row contains six bindings in columns 4-6 and 9-11.
- Preserve the existing four-row structure.

Visual representation:

```text
01 02 03 04 05 06 07 08 09 10 11 12 13 14
01 02 03 04 05 06 07 08 09 10 11 12 13 14
01 02 03 04 05 06       09 10 11 12 13 14
         04 05 06       09 10 11
```

### Verification

- Do not report the Corne PDF as generated or visually verified until the
  PDF tool explicitly supports the Corne key count, layer count, and page
  layout.
- Corne firmware changes are ultimately verified through the corresponding
  left and right GitHub Actions jobs when the user chooses to run them.

## Other configuration files

- `west.yml` pins the ZMK version and must only be changed when explicitly
  requested.
- `sensors[].label` fields in physical-layout JSON files are metadata and do
  not by themselves indicate that physical encoders are installed.
- Do not infer permission to change a `.conf` or physical-layout `.json`
  file from a request that only concerns a keymap.

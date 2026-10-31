# User keyboard configuration instructions

These instructions apply to files under `config/` in addition to the
repository-wide instructions in the root `AGENTS.md`.

## Keyboard ownership

- `sofle_choc_pro.keymap`, `sofle_choc_pro.conf`, and
  `sofle_choc_pro.json` belong to the Sofle Choc Pro.
- `corne_choc_pro.keymap`, `corne_choc_pro.conf`, and
  `corne_choc_pro.json` belong to the Corne Choc Pro.
- `corne_choc_pro_5col.keymap`, `corne_choc_pro_5col.conf`, and
  `corne_choc_pro_5col.json` belong to the five-column Corne Choc Pro variant.
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
- The keymap contains seven active layers and 60 physical keys per layer.

### Layout design invariants

- The active `NAV` layer occupies layer 1 and provides navigation on the
  right half. Its left half contains explicit home-row modifiers and the
  editing row; its six inner thumb bindings remain transparent.
- The separate `NUM` layer contains the number pad on the right half. Its left
  half is disabled except for explicit left-side home-row modifiers; its three
  used left thumb positions remain transparent.
- Use regular number keycodes (`N0`-`N9`) on the `NUM` layer instead of keypad
  keycodes so number entry remains independent of Num Lock.
- The `SHORT` layer contains operating-system and application shortcuts. It is
  activated from the lower-left base-layer key, which sends `Cmd+Space` when
  tapped. Keep `FN_SYM` focused on function keys, brackets, and modifiers.
- Do not add automatic activation for the `SYS` layer; it must not use a
  `conditional_layers` rule.
- Preserve the separate positional home-row-mod behaviors `hml` and `hmr`.
  Each behavior is triggered by the opposite keyboard half plus the six used
  middle thumb positions 52-57. The four outer physical thumb positions 50,
  51, 58, and 59 remain excluded and use `&none` on every layer.
- Preserve the matching `&tog NUM` bindings on the `FN_SYM` and `NUM` layers;
  they provide the lock and unlock path for the `NUM` layer.
- Preserve the one-handed editing row on the outer lower key and `Z`, `X`,
  `C`, `V`, and `B` in the `NAV` and inactive `LNAV` layers: redo, undo,
  cut, copy, paste, and Space.
- Preserve the commented-out `nav_backup_layer` and `lnav_layer` at the end of
  the keymap as inactive references while the navigation layers are being
  redesigned. Neither may receive a layer define or activation binding.
- The active `nav_layer` mirrors navigation onto the right hand while
  preserving the spatial meaning of left, right, up, and down.
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
- Review all generator warnings and visually inspect all generated preview
  pages.

## Corne Choc Pro (`corne_choc_pro.keymap`)

### Preparation status

- This is the active Corne user keymap, but it has not yet been migrated to
  the current Sofle layout design.
- The current Corne board definition and physical-layout JSON expose 46 key
  positions: 14 in each of rows 1 and 2, 12 in row 3, and six thumb keys.
- The target hardware uses the normal six-column firmware target with dual
  displays and no encoders. Its matrix retains all 46 firmware positions, but
  positions 6, 7, 20, and 21 are covered by the displays and cannot be fitted
  with switches, leaving 42 usable keys.
- The separate `corne_choc_pro_5col` target exposes 40 positions and is not the
  target hardware for this migration.
- The Corne keymap contains eight active layers: macos, num, sym, fn, nav,
  win, sys, and numpad. The num layer contains a number row and function keys
  and currently has no activation binding.
- Do not migrate the Sofle keymap wholesale. Transfer behaviors and layer
  concepts deliberately and recalculate all Corne position lists.
- Keep the Sofle configuration read-only while the Corne is the target
  keyboard.
- The Corne `macos` layer maps the Sofle alpha, home, and lower rows onto its
  three main rows; the Sofle number row and its two bracket inner keys are not
  part of the Corne base layer.
- Preserve the separate positional `hml` and `hmr` behaviors. Their Corne
  trigger lists use the opposite 18-key main half plus all six thumb positions
  40-45, excluding the four unavailable display positions.

### Matrix formatting

After every modification to `corne_choc_pro.keymap`, format every active and
commented-out `bindings = < ... >` block according to the physical Corne
matrix described below.

Treat every layer as 14 logical columns:

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

- Positions 6, 7, 20, and 21 still occupy logical columns 7-8 in rows 1-2
  even though the displays prevent physical switches from being fitted there.
- Positions 6, 7, 20, and 21 must use `&none` on every active layer.
- Apply the shared matrix-alignment rules independently to each layer.

### Verification

- Do not report the Corne PDF as generated or visually verified until the
  PDF tool explicitly supports the Corne key count, layer count, and page
  layout.
- Corne firmware changes are ultimately verified through the corresponding
  left and right GitHub Actions jobs when the user chooses to run them.
- The Corne PDF must omit positions 6, 7, 20, and 21 from the drawing while
  still validating all 46 firmware bindings per layer.

## Other configuration files

- `west.yml` pins the ZMK version and must only be changed when explicitly
  requested.
- `sensors[].label` fields in physical-layout JSON files are metadata and do
  not by themselves indicate that physical encoders are installed.
- Do not infer permission to change a `.conf` or physical-layout `.json`
  file from a request that only concerns a keymap.

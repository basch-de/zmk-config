# Keymap PDF tool instructions

These instructions apply to files under `tools/keymap-pdf/` in addition to
the repository-wide instructions in the root `AGENTS.md`.

## Current support

- The generator supports `config/sofle_choc_pro.keymap` with
  `config/sofle_choc_pro.json` and `config/corne_choc_pro.keymap` with
  `config/corne_choc_pro.json`.
- The Sofle target validates exactly five active layers and 60 physical keys.
- The Corne target currently validates nine active layers and 46 firmware
  positions. Positions 6, 7, 20, and 21 must be omitted from the drawing because
  the target hardware's dual displays prevent switches from being fitted there.
- Do not report a Piantor PDF as generated or visually verified until explicit
  support for that keyboard has been implemented.
- `./tools/keymap-pdf/generate.sh [target]` is the authoritative entry point.
  Omitting `target` defaults to `sofle_choc_pro`; `all` generates every
  supported target.

## Inputs and outputs

- `config/sofle_choc_pro.json` is the physical-layout source for the Sofle
  PDF generator and must only be changed when the physical geometry changes.
- Generated PDFs belong under `output/pdf/`.
- Preview images and caches belong under `tmp/keymap-pdf/<target>/`.
- Keep each target's Swift module cache between runs to speed up subsequent
  PDF generation.
- Do not commit generated files from `output/` or `tmp/`.
- Keep preview and cache outputs isolated by target so one keyboard cannot
  overwrite another keyboard's validation artifacts.

## Generator behavior

- Review every generator warning. Unknown keys or behaviors may require a
  label, color category, or activation parser update.
- Layer activation descriptions must be derived from the keymap and must not
  be hard-coded.
- Layer behaviors must use the dedicated layer color.
- Valid ZMK syntax takes precedence over limitations of the PDF parser.
- If the generator cannot parse a valid keymap construct, improve the
  generator instead of rewriting valid keymap syntax solely for the parser.
- The generator uses the existing macOS Swift toolchain and requires no
  project-local dependency installation. If the required toolchain or
  frameworks are unavailable, do not report the PDF as generated or visually
  verified.
- Do not install dependencies or add alternative PDF tooling solely to
  generate or validate the keymap PDF.

## Multi-keyboard preparation

- Keyboard-specific key counts, layer counts, source paths, output names,
  preview directories, page counts, and footer text must be selected from the
  requested target keyboard rather than hard-coded globally.
- Adding support for a keyboard must not change the generated Sofle layout
  unless that change is explicitly requested.
- Adding or removing a layer or physical key requires updating the target
  keyboard's validation and page layout.

## Visual validation

- Run `./tools/keymap-pdf/generate.sh` after every supported keymap or PDF
  generator change.
- Inspect every generated preview page for clipping, overlaps, unreadable
  text, and incorrect physical-key placement.
- After parser changes, verify that every supported current keymap produces
  no unexpected warnings.
- Do not claim successful PDF verification without inspecting the previews
  produced by the latest run.

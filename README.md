# glove80-zmk-config

Keymap/config-only repo for a Moergo Glove80, built against [kalinnorman/zmk_glove80](https://github.com/kalinnorman/zmk_glove80) (a customized fork adding a Seeed XIAO BLE dongle and RGB battery indicators) instead of Moergo's own [`moergo-sc/zmk`](https://github.com/moergo-sc/zmk).

Modeled on Moergo's official [`glove80-zmk-config`](https://github.com/moergo-sc/glove80-zmk-config) template (Nix-only, no `west`/Zephyr toolchain required) rather than the [`glove80-zmk-config-west`](https://github.com/moergo-sc/glove80-zmk-config-west) template, since Moergo's own docs point people at the non-`west` one as the current/recommended path.

The point of this repo: edit `config/glove80.keymap` here, without needing to touch or rebuild the full `zmk_glove80` firmware fork. The firmware fork still owns everything that isn't the keymap - the dongle shield, the RGB underglow/battery code, board definitions, etc.

## Layout

- `config/glove80.keymap` - the keymap. Edit this for keymap changes.
- `config/glove80.conf` - extra Kconfig for the LH/RH halves (currently empty).
- `config/glove80_lh_dongle_peripheral.conf` - extra Kconfig for the LH half specifically when running in dongle-peripheral mode (mirrors the same file in the firmware fork).
- `config/default.nix` - Nix build definitions. Exposes: `glove80_left`, `glove80_right`, `glove80_combined` (both halves in one `.uf2`), and the dongle-mode counterparts `glove80_dongle_left`/`glove80_dongle_right`/`glove80_dongle_xiao`, plus `glove80_settings_reset_{xiao,left,right}`.

## Building via GitHub Actions (primary path)

Push to this repo and the `Build` workflow (`.github/workflows/build.yml`) builds every target above against the `xiao-ble-dongle-rgb` branch of `zmk_glove80`, and bundles the resulting `.uf2` files into one `glove80-firmware` artifact you can download from the Actions run.

If the customizations get merged into `zmk_glove80`'s `main` branch, update the `ref:` in that workflow file accordingly.

## Building locally with Nix

Requires [Nix](https://nixos.org/) installed (see the devcontainer's `Dockerfile`, which installs it) and, for reasonable build times, the `moergo-glove80-zmk-dev` Cachix binary cache configured (`cachix use moergo-glove80-zmk-dev`) so you're not compiling the whole Zephyr/GCC toolchain from source.

`config/default.nix` expects a checkout of the firmware fork at `../src` relative to itself (i.e. a `src/` directory next to `config/`, at this repo's root) - that's what CI sets up via `actions/checkout`. Locally, instead of a second clone, symlink it to an existing checkout, e.g. from this repo's root:

```sh
ln -s ../repo_zmk_glove80 src   # if this repo lives next to repo_zmk_glove80, as in this workspace
```

Then build a target:

```sh
nix-build config -A glove80_left -o result
# firmware is at result/zmk.uf2
```

Build the combined LH+RH image (what you'd actually flash for a non-dongle setup):

```sh
nix-build config -A glove80_combined -o result
```

## Flashing

Same procedure as the firmware fork's own Glove80/dongle setup: double-reset the target (LH half, RH half, or the XIAO dongle) into its UF2 bootloader, then copy the matching `.uf2` file onto the drive that appears. Flash the matching `glove80_settings_reset_*` image first if a board was previously paired in a different role (e.g. switching a half between dongle-peripheral and standalone-central mode).

# Config-only Nix build, modeled on Moergo's official glove80-zmk-config
# (https://github.com/moergo-sc/glove80-zmk-config), but pointed at our own
# customized firmware fork instead of moergo-sc/zmk directly, since the
# XIAO BLE dongle shield and RGB battery indicator code live there.
#
# `firmware` is expected to be the attrset produced by that fork's own
# top-level default.nix (i.e. `import <checkout-of-zmk_glove80> {}`) - see
# ../src, which CI populates via `actions/checkout` and which locally is a
# symlink to ../../repo_zmk_glove80 for fast iteration against this
# workspace's checkout without a second clone.
{ pkgs ? import <nixpkgs> {}
, firmware ? import ../src {}
}:

let
  config = ./.;

  mkHalf = { board, kconfig ? "${config}/glove80.conf" }: firmware.zmk.override {
    inherit board kconfig;
    keymap = "${config}/glove80.keymap";
  };

  glove80_left = mkHalf { board = "glove80_lh"; };
  glove80_right = mkHalf { board = "glove80_rh"; };

  # Peripheral-mode halves for the XIAO BLE dongle setup - same keymap, plus
  # the LH's dongle-peripheral Kconfig overlay (see glove80_lh_dongle_peripheral.conf).
  glove80_dongle_left = mkHalf {
    board = "glove80_lh";
    kconfig = "${config}/glove80_lh_dongle_peripheral.conf";
  };
  glove80_dongle_right = mkHalf { board = "glove80_rh"; };
in {
  inherit glove80_left glove80_right glove80_dongle_left glove80_dongle_right;

  glove80_combined = firmware.combine_uf2 glove80_left glove80_right "glove80";

  # The XIAO is the split-central in dongle mode - it's what actually runs the
  # keymap logic (layers/combos/hold-taps), so it needs this repo's keymap too,
  # unlike the LH/RH peripherals above (keymap content on a peripheral is unused).
  glove80_dongle_xiao = firmware.zmk.override {
    board = "seeeduino_xiao_ble";
    shield = "glove80_dongle";
    keymap = "${config}/glove80.keymap";
  };

  # The settings_reset images don't run any keymap logic at all, so just
  # forward the firmware fork's own attrs.
  glove80_settings_reset_xiao = firmware.glove80_settings_reset_xiao;
  glove80_settings_reset_left = firmware.glove80_settings_reset_left;
  glove80_settings_reset_right = firmware.glove80_settings_reset_right;
}

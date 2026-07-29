# Video Coin Action SVG Icon

## Status

Active

## Scope

- Affected paths: `assets/images/coin-paid.svg`, `assets/images/coin-unpaid.svg`, `lib/common/assets.dart`, `lib/common/widgets/svg/coin_icon.dart`, and video action controls.
- Upstream relationship: upstream-compatible.

## Intent

Replace the Font Awesome `B` glyph used for the video coin action with supplied selected and unselected coin SVGs.

## Implementation

- `coin-paid.svg` uses the standard `640x640` action-icon canvas and a `64px` outer margin; `coin-unpaid.svg` uses the matching `48px` circular ring and fills the currency shape. Both states use the same flattened currency-path coordinates, centered at `(320, 320)`, so switching states cannot change the glyph's placement or scale.
- `CoinIcon` selects `Assets.coinPaid` for the paid state and `Assets.coinUnpaid` for the unpaid state. It colors either SVG with `srcIn`, keeps the existing accessibility label, and renders both at `22.5px`. The SVGs' `80%`-wide visible circle then matches the `18px` visible width of the Font Awesome clock glyph used by the adjacent watch-later action.
- The superseded action SVG resources have been removed.
- `ActionItem.iconBuilder` and `selectIconBuilder` supply the current action color to non-`Icon` renderers without changing existing `Icon` behavior. UGC and PGC pass the calculated action color to both states; the player header fixes the unselected icon to white and passes the selected theme color through.

## Validation

- Docker: `tool/docker_flutter.sh dart format lib/common/assets.dart lib/common/widgets/svg/coin_icon.dart` and targeted `flutter analyze` completed with no issues.
- Docker: `tool/docker_flutter.sh flutter build bundle` passed and packaged the paid and unpaid SVG assets.
- Docker: SVGO `4.0.2` flattened the currency-path transforms at six-decimal precision; XML checks confirmed both `640x640` viewBoxes, preserved paid-state `evenodd` filling, and no remaining `transform` attributes.
- Docker: `tool/docker_flutter.sh flutter build apk --debug --pub` passed; the debug app installed and launched successfully on Genymotion.
- `git diff --check` passed.

## Follow-up

None.
import 'package:PiliPlus/common/assets.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

class CoinIcon extends StatelessWidget {
  const CoinIcon({
    super.key,
    required this.selected,
    required this.color,
  });

  final bool selected;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final size = selected ? 18.0 : 20.0;
    return SvgPicture.asset(
      selected ? Assets.coinAction : Assets.coinActionUnselected,
      width: size,
      height: size,
      colorFilter: ColorFilter.mode(color, BlendMode.srcIn),
      semanticsLabel: '投币',
    );
  }
}
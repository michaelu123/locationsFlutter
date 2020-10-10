import 'dart:ui';

import 'package:flutter/widgets.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_map/plugin_api.dart';

class CrossHairLayerOptions extends LayerOptions {
  final CrossHair crossHair;
  CrossHairLayerOptions({
    Key key,
    this.crossHair,
    rebuild,
  }) : super(key: key, rebuild: rebuild);
}

class CrossHair {
  final Color color;
  CrossHair({
    this.color,
  });
}

class CrossHairLayerWidget extends StatelessWidget {
  final CrossHairLayerOptions options;

  CrossHairLayerWidget({@required this.options}) : super(key: options.key);

  @override
  Widget build(BuildContext context) {
    final mapState = MapState.of(context);
    return CrossHairLayer(options, mapState, mapState.onMoved);
  }
}

class CrossHairLayer extends StatelessWidget {
  final CrossHairLayerOptions circleOpts;
  final MapState map;
  final Stream<Null> stream;
  CrossHairLayer(this.circleOpts, this.map, this.stream)
      : super(key: circleOpts.key);

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (BuildContext context, BoxConstraints bc) {
        final size = Size(bc.maxWidth, bc.maxHeight);
        return _build(context, size);
      },
    );
  }

  Widget _build(BuildContext context, Size size) {
    return StreamBuilder<void>(
      stream: stream, // a Stream<void> or null
      builder: (BuildContext context, _) {
        return CustomPaint(
          painter: CrossHairPainter(circleOpts.crossHair),
          size: size,
        );
      },
    );
  }
}

class CrossHairPainter extends CustomPainter {
  final CrossHair crossHair;
  CrossHairPainter(this.crossHair);

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;

    canvas.clipRect(rect);
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..color = crossHair.color
      ..strokeWidth = 1;

    Offset p1 = Offset(rect.width / 2, 0);
    Offset p2 = Offset(rect.width / 2, rect.height);
    canvas.drawLine(p1, p2, paint);
    p1 = Offset(0, rect.height / 2);
    p2 = Offset(rect.width, rect.height / 2);
    canvas.drawLine(p1, p2, paint);
  }

  @override
  bool shouldRepaint(CrossHairPainter other) => false;
}

class CrossHairMapPlugin extends MapPlugin {
  @override
  Widget createLayer(
      LayerOptions options, MapState mapState, Stream<Null> stream) {
    return CrossHairLayer(options, mapState, stream);
  }

  @override
  bool supportsLayer(LayerOptions options) {
    return options is CrossHairLayerOptions;
  }
}

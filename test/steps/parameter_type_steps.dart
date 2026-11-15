import 'package:ogurets/ogurets.dart';

enum Color { red, green, blue }

final colorType = ParameterType<Color>(
  'color',
  r'red|green|blue',
  'Color',
  (groups) => Color.values.byName(groups.first!),
);

class ParameterTypeSteps {
  static final received = <Object?>[];

  @Given("a {color} ball")
  void aBall(Color color) => received.add(color);

  @Given(r"^a regex step with a (red|green|blue) cube$")
  void aCube(Color color) => received.add(color);

  @Given("{int} {color} balls")
  void balls(int count, Color color) => received.addAll([count, color]);
}

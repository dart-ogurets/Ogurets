import 'package:ogurets/ogurets.dart';
import 'package:ogurets_examples/factory_instance.dart';

class FactoryStepdefs {
  FactoryInstance factoryInstance;

  FactoryStepdefs(this.factoryInstance);

  @And("Hello Factory Instance")
  void hello() {
    assert(factoryInstance.a == factoryInstance.b.a, 'constructured badly');
  }
}

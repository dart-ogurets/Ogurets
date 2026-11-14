import 'package:ogurets/ogurets.dart';

import 'package:ogurets_examples/shared_instance.dart';

class SharedInstanceStepdef {
  final SharedInstance _sharedInstance;

  SharedInstanceStepdef(this._sharedInstance);

  @And("Shared instance count is still 1")
  void stillOne() {
    if (_sharedInstance.count != 1) {
      throw Exception(
        "new instances of the shared instance are being created by the construction injection ${_sharedInstance.count} and should be 1.",
      );
    }
  }
}

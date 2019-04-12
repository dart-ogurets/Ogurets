

import 'package:dherkin3/dherkin_core.dart';

import '../lib/shared_instance.dart';

class SharedInstanceStepdef {
  SharedInstance _sharedInstance;

  SharedInstanceStepdef(this._sharedInstance);

  @And("Shared instance count is still 1")
  void stillOne() {
    if (_sharedInstance.count != 1) {
      throw new Exception("new instances of the shared instance are being created by the construction injection.");
    }
  }

}
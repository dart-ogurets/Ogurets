

class SharedInstance {
  static int instanceCount = 0;

  SharedInstance() {
    instanceCount ++;
  }

  int get count {
    return instanceCount;
  }
}
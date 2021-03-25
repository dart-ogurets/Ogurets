class ClassA {}

class ClassB {
  ClassA a;

  ClassB({required this.a});
}

class FactoryInstance {
  ClassA a;
  ClassB b;

  // we cannot just "create" these instances in the constructor
  // as B depends on A, so we need a factory to do this for us
  FactoryInstance._(this.a, this.b);

  factory FactoryInstance.create() {
    ClassA a = ClassA();
    ClassB b = ClassB(a: a);

    return FactoryInstance._(a, b);
  }
}

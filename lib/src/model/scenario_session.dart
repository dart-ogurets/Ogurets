part of ogurets;

class OguretsScenarioSession {
  Map<Type, InstanceMirror> _scenarioInstances = {};

  OguretsScenarioSession(this._scenarioInstances);

  void addInstance(Type type, InstanceMirror instance) {
    _scenarioInstances.putIfAbsent(type, () => instance);
  }

  void copyShared(Map<Type, InstanceMirror> sharedInstances) {
    _scenarioInstances.addAll(sharedInstances);
  }

  List<DeclarationMirror> _constructors(ClassMirror mirror) {
    return List.from(mirror.declarations.values.where((declare) {
      return declare is MethodMirror && declare.isConstructor;
    }));
  }

  List<ParameterMirror> _params(var methodMirror) {
    if (methodMirror is MethodMirror) {
      return methodMirror.parameters;
    } else {
      return [];
    }
  }

// recursively construct the object if necessary and stick each one into
// the instances map
  InstanceMirror _newInstance(
      ClassMirror cm, Map<Type, InstanceMirror> instances) {
    InstanceMirror newInst;

    List<DeclarationMirror> c = _constructors(cm);
    if (c.isNotEmpty) {
      DeclarationMirror constructor = c[0];
      List<ParameterMirror> params = _params(constructor);
      List<Object> positionalArgs = [];
      // find the positional arguments in the existing instances map, and if they aren't
      // there try and recursively create them. This will of course explode with a stack overflow
      // if we have a circular situation.
      params.forEach((p) {
        InstanceMirror inst = instances[p.type.reflectedType];
        if (inst == null) {
          inst = _newInstance(reflectClass(p.type.reflectedType), instances);
        }
        positionalArgs.add(inst.reflectee);
      });

      Symbol constName = constructor.simpleName == cm.simpleName
          ? const Symbol("")
          : constructor.simpleName;
      newInst = cm.newInstance(constName, positionalArgs);
      instances[cm.reflectedType] = newInst;
    } else {
      newInst = cm.newInstance(const Symbol(""), []);
      instances[cm.reflectedType] = newInst;
    }

    return newInst;
  }

  InstanceMirror getInstance(Type type) {
    InstanceMirror im = _scenarioInstances[type];

    if (im == null) {
      im = _newInstance(reflectClass(type), _scenarioInstances);
    }

    return im;
  }
}

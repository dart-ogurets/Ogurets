part of ogurets;

class OguretsScenarioSession {
  Map<Type, InstanceMirror> _scenarioInstances = {};
  Map<Type, InstanceMirror> _sharedInstances = {};

  OguretsScenarioSession(this._scenarioInstances);

  void addInstance(Type type, InstanceMirror instance) {
    _scenarioInstances.putIfAbsent(type, () => instance);
  }

  void copyShared(Map<Type, InstanceMirror> sharedInstances) {
    _scenarioInstances.addAll(sharedInstances);
  }

  List<MethodMirror> _constructors(ClassMirror mirror) {
    return mirror.declarations.values
        .whereType<MethodMirror>()
        .where((MethodMirror declare) =>
            declare.isConstructor || declare.isFactoryConstructor)
        .sorted((MethodMirror a, MethodMirror b) =>
            (a.isFactoryConstructor ? 'a' : 'b')
                .compareTo(b.isFactoryConstructor ? 'a' : 'b'));
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

    // In case of abstract class type parameter, try to get a subclass to instantiate
    ClassMirror? subclassMirror;
    if (cm.isAbstract) {
      for (final libMirror in currentMirrorSystem().libraries.values) {
        if (libMirror.declarations.isNotEmpty) {
          for (final classMirror in libMirror.declarations.values) {
            if (classMirror is ClassMirror && classMirror.superclass == cm) {
              subclassMirror = classMirror;
              break;
            }
          }
        }
        if (subclassMirror != null) {
          break;
        }
      }
    }
    final mirror = subclassMirror ?? cm;
    List<MethodMirror> c = _constructors(mirror);
    if (c.isNotEmpty) {
      MethodMirror constructor = c[0];
      List<ParameterMirror> params = _params(constructor);
      List<Object?> positionalArgs = [];
      // find the positional arguments in the existing instances map, and if they aren't
      // there try and recursively create them. This will of course explode with a stack overflow
      // if we have a circular situation.
      params.forEach((p) {
        InstanceMirror? inst = instances[p.type.reflectedType];
        if (inst == null) {
          // Check if we already have a concrete subclass available before instantiating a new one
          for (final instance in instances.values) {
            if (p.type == instance.type.superclass) {
              inst = instance;
              break;
            }
          }
          inst = inst ?? _newInstance(reflectClass(p.type.reflectedType), instances);
        }
        positionalArgs.add(inst.reflectee);
      });

      if (constructor.isFactoryConstructor) {
        newInst = mirror.newInstance(constructor.constructorName, positionalArgs);
      } else {
        Symbol constName = constructor.simpleName == mirror.simpleName
            ? const Symbol("")
            : constructor.simpleName;
        newInst = mirror.newInstance(constName, positionalArgs);
      }
    } else {
      newInst = mirror.newInstance(const Symbol(""), []);
    }
    // Make sure to link the resolved subclass to both itself as the abstract class it was resolved for in the first place
    if (mirror.reflectedType != cm.reflectedType) {
      instances[mirror.reflectedType] = newInst;
    }
    instances[cm.reflectedType] = newInst;

    return newInst;
  }

  InstanceMirror getInstance(Type type) {
    InstanceMirror? im = _scenarioInstances[type];

    if (im == null) {
      im = _newInstance(reflectClass(type), _scenarioInstances);
    }

    return im;
  }
}

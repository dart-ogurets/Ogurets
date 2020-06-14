part of ogurets;

class Hook {
  final String tag;
  final int order; // lowest -> highest
  const Hook({this.tag, this.order});
}

class Before extends Hook {
  const Before({String tag, int order}) : super(tag: tag, order: order);
}

class After extends Hook {
  const After({String tag, int order}) : super(tag: tag, order: order);
}

class BeforeStep extends Hook {
  const BeforeStep({String tag, int order}) : super(tag: tag, order: order);
}

class AfterStep extends Hook {
  const AfterStep({String tag, int order}) : super(tag: tag, order: order);
}

// only available on given instances
class BeforeRun {
  final int order;

  const BeforeRun({this.order});
}

// only available on given instances
class AfterRun {
  final int order;

  const AfterRun({this.order});
}

class StepDef {
  final String verbiage;

  const StepDef(this.verbiage);
}

class Given extends StepDef {
  const Given(verbiage) : super(verbiage);
}

class And extends StepDef {
  const And(verbiage) : super(verbiage);
}

class But extends StepDef {
  const But(verbiage) : super(verbiage);
}

class When extends StepDef {
  const When(verbiage) : super(verbiage);
}

class Then extends StepDef {
  const Then(verbiage) : super(verbiage);
}

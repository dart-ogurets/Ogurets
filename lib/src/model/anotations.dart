part of dherkin_core;

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

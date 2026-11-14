part of '../../ogurets.dart';

class Hook {
  final String? tag;
  final int? order; // lowest -> highest
  const Hook({this.tag, this.order});
}

class Before extends Hook {
  const Before({super.tag, super.order});
}

class After extends Hook {
  const After({super.tag, super.order});
}

class BeforeStep extends Hook {
  const BeforeStep({super.tag, super.order});
}

class AfterStep extends Hook {
  const AfterStep({super.tag, super.order});
}

// only available on given instances
class BeforeRun {
  final int? order;

  const BeforeRun({this.order});
}

// only available on given instances
class AfterRun {
  final int? order;

  const AfterRun({this.order});
}

/// The base class of the step annotations, which ogurets uses to find steps.
///
/// Don't annotate steps with `@StepDef` - it is not a standard Gherkin keyword,
/// and Cucumber tooling such as the IntelliJ plugin won't recognise it. Use
/// [Given], [When], [Then], [And] or [But] instead.
class StepDef {
  final String verbiage;

  const StepDef(this.verbiage);
}

class Given extends StepDef {
  const Given(super.verbiage);
}

class And extends StepDef {
  const And(super.verbiage);
}

class But extends StepDef {
  const But(super.verbiage);
}

class When extends StepDef {
  const When(super.verbiage);
}

class Then extends StepDef {
  const Then(super.verbiage);
}

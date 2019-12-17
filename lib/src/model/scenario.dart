part of ogurets_core3;

class Scenario {
  // todo: Fetch this from GherkinVocabulary or something
  String gherkinKeyword = "Scenario";

  String name;

  List<String> tags;

  Scenario background;

  List<Step> steps = [];
  GherkinTable examples = GherkinTable();

  Location location;

  Scenario(this.name, this.location);

  /// Will execute the background and the scenario.
  /// If this scenario has an example table, it will execute all the generated scenarios,
  /// each with its own background, but background will be added to this scenario's buffer only once.
  Future<List<ScenarioStatus>> execute(OguretsState state,
      {isFirstOfFeature = true, OguretsScenarioSession scenarioSession}) async {
    var statuses = <ScenarioStatus>[];

    if (examples._table.isEmpty) {
      examples._table.add({});
    }

    state.fmt.startOfScenarioLifeCycle(this);

    if (examples.isValid) {
      state.fmt.examples(examples);
    }

    for (Map example in examples) {
      var scenarioStatus = ScenarioStatus(state.fmt)
        ..scenario = this
        ..exampleTable = this.examples
        ..example = example
        ..background = this.background;

      statuses.add(scenarioStatus);
      state.fmt.scenario(scenarioStatus);

      try {
        await _executeSubScenario(scenarioStatus, example, state,
            isFirstOfFeature: isFirstOfFeature,
            scenarioSession: scenarioSession);
      } finally {
        state.fmt.done(scenarioStatus);
      }
    }

    if (examples.isValid) {
      state.fmt.done(examples);
    }

    state.fmt.endOfScenarioLifeCycle(this);

    return statuses;
  }

  void addStep(Step step) {
    steps.add(step);
  }

  String toString() {
    return "${tags == null ? "" : tags} $name $steps \nExamples: $examples";
  }

  Future<ScenarioStatus> _executeSubScenario(
      ScenarioStatus scenarioStatus, exampleRow, OguretsState state,
      {isFirstOfFeature = true, OguretsScenarioSession scenarioSession}) async {
    List<ScenarioStatus> backgroundStatus;

    if (scenarioSession == null) {
      scenarioSession =
          OguretsScenarioSession({}..addAll(state.existingInstances));
    }

    await state.runBeforeHooks(scenarioStatus, scenarioSession);

    try {
      if (background != null) {
        backgroundStatus =
            await background.execute(state, scenarioSession: scenarioSession);
      }

      if (backgroundStatus != null && backgroundStatus.isNotEmpty) {
        scenarioStatus.mergeBackground(backgroundStatus[0],
            isFirst: isFirstOfFeature);
      }

      var iter = steps.iterator;
      while (iter.moveNext()) {
        var step = iter.current;
        var stepStatus = StepStatus(state.fmt)
          ..step = step
          ..decodedVerbiage = step.decodeVerbiage(exampleRow);

        state.fmt.step(stepStatus);

        var found = state.stepRunners.keys.firstWhere(
            (RegExp key) => key.hasMatch(stepStatus.decodedVerbiage),
            orElse: () => null);

        if (found == null) {
          stepStatus.defined = false;
          state.fmt.done(stepStatus);
          scenarioStatus.undefinedSteps.add(stepStatus);
          continue;
        }

        var match = found.firstMatch(stepStatus.decodedVerbiage);

        // (unrelated) Notes :
        // The FeatureContext class approach for stepdefs makes sense :
        // - you implement methods and wrap them with annotations.
        // - you use properties as you want as context shared by steps.

        // Parameters from Regex
        var params = [];
        for (var i = 1; i <= match.groupCount; i++) {
          params.add(Step.unserialize(match.group(i)));
        }
        // PyString
        if (step.pyString != null) {
          params.add(step.pyString);
        }

        Map<String, dynamic> moreParams = {"out": stepStatus.out};

        if (!exampleRow.isEmpty) {
          moreParams["exampleRow"] = exampleRow;
        }

        if (!step.table.empty) {
          moreParams["table"] = step.table;
        }

        try {
          if (scenarioStatus.failed) {
            stepStatus.skipped = true;
          } else {
            // to actually run the step
            await state.stepRunners[found](params, moreParams, scenarioSession, scenarioStatus, stepStatus);
          }
        } catch (e) {
          _log.fine("Step failed: $step");
        } finally {
          if (!stepStatus.failed && !scenarioStatus.failed) {
            scenarioStatus.passedSteps.add(stepStatus);
          }
          state.fmt.done(stepStatus);
        }
      }
    } finally {
      await state.runAfterHooks(scenarioStatus, scenarioSession);
    }

    return scenarioStatus;
  }
}

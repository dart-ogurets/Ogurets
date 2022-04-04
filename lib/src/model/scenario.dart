part of ogurets;

class _Scenario {
  // todo: Fetch this from GherkinVocabulary or something
  String gherkinKeyword = "Scenario";

  String? name;

  List<String?>? tags;

  _Scenario? background;

  List<_Step?> steps = [];
  GherkinTable examples = GherkinTable();

  Location location;

  _Scenario(this.name, this.location);

  /// Will execute the background and the scenario.
  /// If this scenario has an example table, it will execute all the generated scenarios,
  /// each with its own background, but background will be added to this scenario's buffer only once.
  Future<List<ScenarioStatus>> execute(OguretsState state,
      {isFirstOfFeature = true,
      OguretsScenarioSession? scenarioSession,
      bool skip = false}) async {
    var statuses = <ScenarioStatus>[];

    if (examples._table.isEmpty) {
      examples._table.add({});
    }

    // only call the formatters if the scenario is actually run
    if (!skip) {
      state.fmt!.startOfScenarioLifeCycle(this);

      if (examples.isValid) {
        state.fmt!.examples(examples);
      }
    }

    // this needs to run even if skipping to get an accurate scenario count
    for (Map example in examples) {
      var scenarioStatus = ScenarioStatus(state.fmt)
        ..scenario = this
        ..exampleTable = this.examples
        ..example = example
        ..background = this.background as _Background?;

      statuses.add(scenarioStatus);

      // only call the formatters if the scenario is actually run
      if (!skip) {
        state.fmt!.scenario(scenarioStatus);

        try {
          await _executeSubScenario(scenarioStatus, example, state,
              isFirstOfFeature: isFirstOfFeature,
              scenarioSession: scenarioSession);
        } finally {
          scenarioStatus.sw.stop();
          state.fmt!.done(scenarioStatus);
        }

        if (examples.isValid) {
          state.fmt!.done(examples);
        }

        state.fmt!.endOfScenarioLifeCycle(this);
      } else {
        scenarioStatus.sw.stop();
        scenarioStatus.skipped = true;
      }
    }

    return statuses;
  }

  void addStep(_Step? step) {
    steps.add(step);
  }

  String toString() {
    return "${tags == null ? "" : tags} $name $steps \nExamples: $examples";
  }

  Future<ScenarioStatus> _executeSubScenario(
      ScenarioStatus scenarioStatus, exampleRow, OguretsState state,
      {isFirstOfFeature = true,
      OguretsScenarioSession? scenarioSession}) async {
    List<ScenarioStatus>? backgroundStatus;

    if (scenarioSession == null) {
      scenarioSession =
          OguretsScenarioSession({}..addAll(state.existingInstances));
    }

    await state.runBeforeHooks(scenarioStatus, scenarioSession);

    try {
      if (background != null) {
        backgroundStatus =
            await background!.execute(state, scenarioSession: scenarioSession);
      }

      if (backgroundStatus != null && backgroundStatus.isNotEmpty) {
        scenarioStatus.mergeBackground(backgroundStatus[0],
            isFirst: isFirstOfFeature);
      }

      var iter = steps.iterator;
      while (iter.moveNext()) {
        var step = iter.current!;
        var stepStatus = StepStatus(state.fmt)
          ..step = step
          ..decodedVerbiage = step.decodeVerbiage(step.verbiage, exampleRow);

        state.fmt!.step(stepStatus);

        var found = state.stepRunners.keys.firstWhereOrNull(
            (RegExp key) => key.hasMatch(stepStatus.decodedVerbiage!));

        if (found == null) {
          stepStatus.defined = false;
          state.fmt!.done(stepStatus);
          scenarioStatus.undefinedSteps.add(stepStatus);
          continue;
        }

        var match = found.firstMatch(stepStatus.decodedVerbiage!)!;

        // (unrelated) Notes :
        // The FeatureContext class approach for stepdefs makes sense :
        // - you implement methods and wrap them with annotations.
        // - you use properties as you want as context shared by steps.

        // Parameters from Regex
        var params = [];
        for (var i = 1; i <= match.groupCount; i++) {
          params.add(_Step.unserialize(match.group(i)!));
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
          // Replace placeholders with exampleRow values
          final newTable = GherkinTable();
          for (final oldRow in step.table.gherkinRows()) {
            List<String> newRow = step.decodeVerbiage(oldRow, exampleRow)!.trim().split("|").map((e) => e.trim()).toList()
              ..removeAt(0)..removeLast();
            newTable.addRow(newRow);
          }
          moreParams["table"] = newTable;
        }

        try {
          // should also skip steps where we have a previous one that is undefined - that means the scenario already "failed"
          if (scenarioStatus.failed || scenarioStatus.undefinedStepsCount > 0) {
            stepStatus.skipped = true;
          } else {
            // to actually run the step
            await state.stepRunners[found]!(params, moreParams, scenarioSession,
                scenarioStatus, stepStatus);
          }
        } catch (e, s) {
          _log.fine("Step failed: $step");
          // if we get here and it's not set as failed, make sure to set it.
          // this can happen if there are runtime constructor issues on the step class construction, for example
          if (!stepStatus.failed) {
            stepStatus.failure = StepFailure(e, s.toString());
          }
        } finally {
          if (!stepStatus.failed && !scenarioStatus.failed) {
            scenarioStatus.passedSteps.add(stepStatus);
          }
          state.fmt!.done(stepStatus);
        }
      }
    } finally {
      await state.runAfterHooks(scenarioStatus, scenarioSession);
    }

    return scenarioStatus;
  }
}

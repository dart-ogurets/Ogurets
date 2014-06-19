part of dherkin;

class ScenarioExecutionTask implements Task {
   var scenario;

   ScenarioExecutionTask(this.scenario);

   Future<ResultBuffer> execute() {
     LoggerFactory.config[".*"].debugEnabled = false;
     return _scan().then((value) {
       var buffer = new _ConsoleBuffer(); // FIXME fetch proper type of buffer
       scenario.execute(buffer);
       _log.debug("Done executing: ${scenario.name}");
       return [buffer, scenario.hasFailed];
     });
   }
}

class Feature {
   String name;

   List<String> tags;

   Scenario background = _NOOP;
   List<Scenario> scenarios = [];

   Feature(this.name);

   int okScenariosCount = 0;
   int koScenariosCount = 0;

   /**
    * Executes the feature using provided worker
    */
   Future execute(Worker worker) {
     if (_tagsMatch(tags)) {
       var buffer = new _ConsoleBuffer(); // FIXME fetch proper type of buffer
       buffer.write("Feature: $name");

       var completer = new Completer();
       var results = [];
       Future.forEach(scenarios, (scenario) {
         _log.debug("Requested tags: $_runTags.  Scenario is tagged with: ${scenario.tags}");
         if (_tagsMatch(scenario.tags)) {
           _log.debug("Executing Scenario: $scenario");
           scenario.background = background;

           var future = worker.handle(new ScenarioExecutionTask(scenario));

           future.then((output) {
             buffer.merge(output[0]);

             if(output[1]) {
              okScenariosCount++;
             } else {
              koScenariosCount++;
             }
           });

           results.add(future);
         }
       }).whenComplete(() {
         Future.wait(results).whenComplete(() {
           buffer.write("Scenarios passed: $okScenariosCount", color: 'green');

           if(koScenariosCount > 0) {
             buffer.write("Scenarios failed: $koScenariosCount", color: 'red');
           }

           buffer.flush();
           completer.complete();
         });
       });

       return completer.future;
     } else {
       _log.info("Skipping feature $name due to tags not matching");

       return new Future.value("NOOP");
     }
   }

   /**
    * Converts to printable format
    */
   String toString() {
       return "$name ${tags == null ? "" : tags}\n $background \n$scenarios";
     }

}

class Scenario {
   String name;

   List<String> tags;

   Scenario background;

   List<Step> steps = [];
   GherkinTable examples = new GherkinTable();

   bool hasFailed = false;

   Scenario(this.name);

   void execute(ResultBuffer buffer) {
      if (examples._table.isEmpty) {
         examples._table.add({});
      }

      if(background != null) {
        background.execute(buffer);
      }

      var tableIter = examples._table.iterator;
      while (tableIter.moveNext()) {
         var row = tableIter.current;
         buffer.write("\n\tScenario: $name");
         var iter = steps.iterator;
         while (iter.moveNext()) {
            var step = iter.current;
            var found = _stepRunners.keys.firstWhere((key) => key.hasMatch(step.verbiage), orElse: () => _NOTFOUND);

            var match = found.firstMatch(step.verbiage);
            var params = [];
            if (match != null) {
               // Parameters from Regex
               for (var i = 1; i <= match.groupCount; i++) {
                  params.add(match[i]);
               }
               // PyString
               if (step.pyString != null) {
                  params.add(step.pyString);
               }

            } else {
               buffer.missingStepDef(step.verbiage, examples._columnNames);
            }

            var color = "green";
            var extra = "";

            var ctx = {
               "table": step.table
            };
            try {
               _stepRunners[found](ctx, params, row);
            } on StepDefUndefined {
               color = "yellow";
            } catch (e, stack) {
               hasFailed = true;
               _log.debug("Step failed: $step");
               _log.debug(e.toString());
               _log.debug(stack.toString());
               extra = "\n" + e.toString() + "\n" + stack.toString();
               color = "red";
            } finally {
               if (step.pyString != null) {
                  buffer.write("\t\t${step.verbiage}\n\"\"\"\n${step.pyString}\"\"\"$extra", color: color);
               } else {
                  buffer.write("\t\t${step.verbiage}$extra", color: color);
               }
            }
         }
      }

      return buffer;
  }

   void addStep(Step step) {
      steps.add(step);
   }

   String toString() {
      return "${tags == null ? "" : tags} $name $steps \nExamples: $examples";
   }
}

class Step {
   String verbiage;
   String pyString;
   GherkinTable table = new GherkinTable();

   Step(this.verbiage);

   String toString() {
      if (pyString != null) {
         return "$verbiage\n\"\"\"\n$pyString\"\"\"\n$table";
      } else {
         return "$verbiage $table";
      }
   }
}

class GherkinTable {
   List<String> _columnNames = [];
   List<Map> _table = [];

   void addRow(row) {
      if (_columnNames.isEmpty) {
         _columnNames.addAll(row);
      } else {
         _table.add(new Map.fromIterables(_columnNames, row));
      }
   }

   String toString() {
      return _table.toString();
   }
}

class StepDef {
   final String verbiage;

   const StepDef(this.verbiage);
}

class StepDefUndefined implements Exception {

}

final _NOOP = new Scenario("NOOP");

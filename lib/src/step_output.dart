part of '../ogurets.dart';

/// Zone key holding the [StepStatus] whose output is being captured.
final Object _stepOutputKey = Object();

/// Whether step output is shown for every step, not just failed ones.
///
/// Set the `ALWAYS_SHOW_OUT` environment variable (to anything but `false`,
/// `0` or `no`) to show it always. Step output is then not captured either:
/// `print` and log messages appear immediately, as they happen.
final bool alwaysShowOut = _envSet(Platform.environment['ALWAYS_SHOW_OUT']);

bool _envSet(String? value) =>
    value != null && value.isNotEmpty && !_isFalse(value);

/// Runs [body] - a step or hook - capturing its output into [status]'s
/// [StepStatus.out], so it can be shown only if the step fails.
///
/// Captured are: anything written to the step's `out` parameter, `print`
/// calls, and `package:logging` records logged from inside the step
/// (including from code it awaits). Logs from the `ogurets` logger itself
/// are not captured.
Future<T> _captureStepOutput<T>(StepStatus status, Future<T> Function() body) {
  if (alwaysShowOut) {
    return body();
  }

  return runZoned(
    body,
    zoneValues: {_stepOutputKey: status},
    zoneSpecification: ZoneSpecification(
      print: (self, parent, zone, line) => status.out.writeln(line),
    ),
  );
}

/// The step whose output [record] belongs to, if it was logged from inside a
/// step whose output is being captured.
StepStatus? _capturingStep(LogRecord record) {
  final status = record.zone?[_stepOutputKey];
  return status is StepStatus && record.loggerName != 'ogurets' ? status : null;
}

StreamSubscription<LogRecord>? _logCapture;

/// Starts adding log records from inside steps to the step's output (once).
void _captureStepLogs() {
  _logCapture ??= Logger.root.onRecord.listen(_captureLogRecord);
}

void _captureLogRecord(LogRecord record) {
  final status = _capturingStep(record);
  if (status == null) {
    return;
  }

  status.out.writeln(
    '${record.level.name}: ${record.loggerName}: ${record.message}',
  );
  if (record.error != null) {
    status.out.writeln(record.error);
  }
  if (record.stackTrace != null) {
    status.out.writeln(record.stackTrace);
  }
}

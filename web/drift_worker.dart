import 'package:drift/web/worker.dart';
import 'package:drift_flutter/drift_flutter.dart';

void main() {
  driftWorkerMain(() {
    return driftDatabase(
      name: 'pm_database',
      web: DriftWebOptions(
        sqlite3Wasm: Uri.parse('sqlite3.wasm'),
        driftWorker: Uri.parse('drift_worker.dart.js'),
      ),
    );
  });
}

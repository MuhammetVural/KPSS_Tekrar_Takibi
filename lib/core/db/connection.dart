

import 'dart:io';

import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:path_provider/path_provider.dart';

/// Opens the local SQLite database file for Drift.
///
/// The database file will be created (if missing) under the app's documents
/// directory as `kpss_tekrar.db`.
LazyDatabase openConnection() {
  return LazyDatabase(() async {
    final dbFolder = await getApplicationDocumentsDirectory();
    final file = File('${dbFolder.path}/kpss_tekrar.db');
    return NativeDatabase(file);
  });
}
import 'package:drift_dev/api/migrations_native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:perfica/core/database/app_database.dart';

import 'generated_migrations/schema.dart';

void main() {
  late SchemaVerifier verifier;

  setUpAll(() {
    verifier = SchemaVerifier(GeneratedHelper());
  });

  Future<void> verifyMigration(int version) async {
    final connection = await verifier.startAt(version);

    final database = AppDatabase.forTesting(connection);

    try {
      await verifier.migrateAndValidate(database, 6);
    } finally {
      await database.close();
    }
  }

  test('migration from v1 to v6 matches the expected schema', () async {
    await verifyMigration(1);
  });

  test('migration from v2 to v6 matches the expected schema', () async {
    await verifyMigration(2);
  });

  test('migration from v3 to v6 matches the expected schema', () async {
    await verifyMigration(3);
  });

  test('migration from v4 to v6 matches the expected schema', () async {
    await verifyMigration(4);
  });

  test('migration from v5 to v6 matches the expected schema', () async {
    await verifyMigration(5);
  });
}

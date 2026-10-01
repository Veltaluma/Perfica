import 'dart:convert';

import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:perfica/core/database/app_database.dart';
import 'package:perfica/features/focus/data/focus_repository.dart';
import 'package:perfica/features/focus/data/focus_session.dart';

void main() {
  late AppDatabase database;
  late FocusRepository repository;

  setUp(() {
    database = AppDatabase.forTesting(NativeDatabase.memory());

    repository = FocusRepository(database);
  });

  tearDown(() async {
    await database.close();
  });

  test(
    'addSession writes normalized focus_sessions rows in insertion order',
    () async {
      final first = FocusSession(
        completedAt: DateTime(2099, 1, 1, 8),
        durationMinutes: 25,
      );

      final second = FocusSession(
        completedAt: DateTime(2099, 1, 1, 9),
        durationMinutes: 50,
      );

      await repository.addSession(first);
      await repository.addSession(second);

      final rows = await database.select(database.focusSessionRows).get();

      expect(rows, hasLength(2));

      expect(rows.map((row) => row.durationMinutes), [25, 50]);

      final sessions = await repository.getSessions();

      expect(sessions.map((item) => item.completedAt), [
        first.completedAt,
        second.completedAt,
      ]);

      expect(sessions.map((item) => item.durationMinutes), [25, 50]);
    },
  );

  test('normalized focus_sessions is the read source of truth', () async {
    final normalized = FocusSession(
      completedAt: DateTime(2099, 2, 2, 10),
      durationMinutes: 45,
    );

    await repository.addSession(normalized);

    final corruptedLegacy = jsonEncode([
      {'completedAt': '2099-01-01T01:00:00.000', 'durationMinutes': 999},
    ]);

    await database
        .into(database.appMetadata)
        .insertOnConflictUpdate(
          AppMetadataCompanion.insert(
            key: 'focus:sessions:v1',
            value: corruptedLegacy,
            updatedAt: DateTime.now(),
          ),
        );

    final sessions = await repository.getSessions();

    expect(sessions, hasLength(1));

    expect(sessions.single.completedAt, normalized.completedAt);

    expect(sessions.single.durationMinutes, 45);
  });

  test('getSessions falls back to valid legacy metadata when normalized rows are absent', () async {
    final legacyValue = jsonEncode([
      {'completedAt': '2099-03-01T08:00:00.000', 'durationMinutes': 25},
      {'completedAt': '2099-03-01T09:00:00.000', 'durationMinutes': 50},
    ]);

    await database
        .into(database.appMetadata)
        .insertOnConflictUpdate(
          AppMetadataCompanion.insert(
            key: 'focus:sessions:v1',
            value: legacyValue,
            updatedAt: DateTime.now(),
          ),
        );

    final sessions = await repository.getSessions();

    expect(sessions, hasLength(2));

    expect(sessions.map((item) => item.durationMinutes), [25, 50]);
  });

  test('addSession promotes legacy history before appending new normalized session', () async {
    final legacyValue = jsonEncode([
      {'completedAt': '2099-04-01T08:00:00.000', 'durationMinutes': 25},
      {'completedAt': '2099-04-01T09:00:00.000', 'durationMinutes': 50},
    ]);

    await database
        .into(database.appMetadata)
        .insertOnConflictUpdate(
          AppMetadataCompanion.insert(
            key: 'focus:sessions:v1',
            value: legacyValue,
            updatedAt: DateTime.now(),
          ),
        );

    await repository.addSession(
      FocusSession(completedAt: DateTime(2099, 4, 1, 10), durationMinutes: 90),
    );

    final sessions = await repository.getSessions();

    expect(sessions.map((item) => item.durationMinutes), [25, 50, 90]);

    final rows = await database.select(database.focusSessionRows).get();

    expect(rows, hasLength(3));
  });

  test(
    'addSession writes normalized storage without creating legacy metadata',
    () async {
      await repository.addSession(
        FocusSession(completedAt: DateTime(2099, 5, 5, 8), durationMinutes: 25),
      );

      await repository.addSession(
        FocusSession(completedAt: DateTime(2099, 5, 5, 9), durationMinutes: 50),
      );

      final metadataQuery = database.select(database.appMetadata)
        ..where((table) => table.key.equals('focus:sessions:v1'));

      expect(await metadataQuery.getSingleOrNull(), isNull);

      final sessions = await repository.getSessions();

      expect(sessions, hasLength(2));

      expect(sessions.map((item) => item.durationMinutes), [25, 50]);
    },
  );

  test(
    'malformed legacy metadata safely falls back to empty history',
    () async {
      await database
          .into(database.appMetadata)
          .insertOnConflictUpdate(
            AppMetadataCompanion.insert(
              key: 'focus:sessions:v1',
              value: '[{"completedAt":"invalid","durationMinutes":25}]',
              updatedAt: DateTime.now(),
            ),
          );

      expect(await repository.getSessions(), isEmpty);
    },
  );

  test('watchSessions emits normalized focus history', () async {
    final nextHistory = repository.watchSessions().firstWhere(
      (sessions) => sessions.length == 1,
    );

    await repository.addSession(
      FocusSession(completedAt: DateTime(2099, 6, 1, 7), durationMinutes: 30),
    );

    final sessions = await nextHistory;

    expect(sessions.single.durationMinutes, 30);
  });
}

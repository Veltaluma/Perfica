import 'dart:convert';

import 'package:drift/drift.dart';

import '../../../core/database/app_database.dart';
import 'focus_session.dart';

class FocusRepository {
  FocusRepository(this._database);

  static const _legacyKey = 'focus:sessions:v1';

  final AppDatabase _database;

  Future<List<FocusSession>> getSessions() async {
    final rows = await _normalizedRows();

    if (rows.isNotEmpty) {
      return rows
          .map(
            (row) => FocusSession(
              completedAt: row.completedAt,
              durationMinutes: row.durationMinutes,
            ),
          )
          .toList(growable: false);
    }

    return _readLegacySessions();
  }

  Stream<List<FocusSession>> watchSessions() {
    final query = _database.select(_database.focusSessionRows)
      ..orderBy([(table) => OrderingTerm.asc(table.id)]);

    return query.watch().asyncMap((rows) async {
      if (rows.isNotEmpty) {
        return rows
            .map(
              (row) => FocusSession(
                completedAt: row.completedAt,
                durationMinutes: row.durationMinutes,
              ),
            )
            .toList(growable: false);
      }

      return _readLegacySessions();
    });
  }

  Future<void> addSession(FocusSession session) async {
    await _database.transaction(() async {
      final existingRows = await _normalizedRows();

      // Transitional compatibility:
      // if this database still has only valid legacy focus JSON,
      // promote that history before appending the new session.
      if (existingRows.isEmpty) {
        final legacySessions = await _readLegacySessions();

        for (final legacy in legacySessions) {
          await _database
              .into(_database.focusSessionRows)
              .insert(
                FocusSessionRowsCompanion.insert(
                  completedAt: legacy.completedAt,
                  durationMinutes: legacy.durationMinutes,
                ),
              );
        }
      }

      await _database
          .into(_database.focusSessionRows)
          .insert(
            FocusSessionRowsCompanion.insert(
              completedAt: session.completedAt,
              durationMinutes: session.durationMinutes,
            ),
          );

      // Portable backup v3 still backs up AppMetadata.
      // Keep the complete focus history mirrored there until
      // backup/restore is upgraded to normalized v5 storage.
    });
  }

  Future<List<FocusSessionRow>> _normalizedRows() {
    final query = _database.select(_database.focusSessionRows)
      ..orderBy([(table) => OrderingTerm.asc(table.id)]);

    return query.get();
  }

  Future<List<FocusSession>> _readLegacySessions() async {
    final query = _database.select(_database.appMetadata)
      ..where((table) => table.key.equals(_legacyKey));

    final row = await query.getSingleOrNull();

    if (row == null) {
      return const [];
    }

    try {
      final decoded = jsonDecode(row.value);

      if (decoded is! List<dynamic>) {
        return const [];
      }

      final sessions = <FocusSession>[];

      for (final raw in decoded) {
        if (raw is! Map<String, dynamic>) {
          return const [];
        }

        final completedAtValue = raw['completedAt'];

        final durationValue = raw['durationMinutes'];

        if (completedAtValue is! String || durationValue is! num) {
          return const [];
        }

        final completedAt = DateTime.tryParse(completedAtValue);

        if (completedAt == null) {
          return const [];
        }

        sessions.add(
          FocusSession(
            completedAt: completedAt,
            durationMinutes: durationValue.toInt(),
          ),
        );
      }

      return List.unmodifiable(sessions);
    } catch (_) {
      return const [];
    }
  }
}

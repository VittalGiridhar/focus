import 'package:drift/drift.dart';

import '../../../data/db/app_database.dart';
import '../domain/usage_models.dart';

class LimitsRepository {
  LimitsRepository(this._db);

  final AppDatabase _db;

  Stream<List<LimitRule>> watchAll() {
    final query = _db.select(_db.limitRules)
      ..orderBy([(t) => OrderingTerm.asc(t.label)]);
    return query.watch().map((rows) => rows.map(_fromRow).toList());
  }

  Future<void> upsert(LimitRule rule) {
    if (!LimitRule.isValidLimit(rule.dailyLimit)) {
      throw ArgumentError('Limit must be between 1 minute and 12 hours');
    }
    return _db.into(_db.limitRules).insertOnConflictUpdate(
          LimitRulesCompanion.insert(
            appId: rule.appId,
            label: rule.label,
            dailyLimitMinutes: rule.dailyLimit.inMinutes,
            enabled: Value(rule.enabled),
          ),
        );
  }

  Future<void> delete(String appId) =>
      (_db.delete(_db.limitRules)..where((t) => t.appId.equals(appId))).go();

  LimitRule _fromRow(LimitRow r) => LimitRule(
        appId: r.appId,
        label: r.label,
        dailyLimit: Duration(minutes: r.dailyLimitMinutes),
        enabled: r.enabled,
      );
}

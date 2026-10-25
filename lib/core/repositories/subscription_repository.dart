import 'dart:async';
import '../database/database_helper.dart';

abstract class ISubscriptionRepository {
  Future<Set<String>> getSubscribedEntityIds({
    required String userId,
    required String entityType,
  });

  Future<void> addSubscription({
    required String userId,
    required String entityType,
    required String entityId,
  });

  Future<void> removeSubscription({
    required String userId,
    required String entityType,
    required String entityId,
  });

  Future<bool> isSubscribed({
    required String userId,
    required String entityType,
    required String entityId,
  });

  Future<void> clearUserSubscriptions(String userId);
}

class SqliteSubscriptionRepository implements ISubscriptionRepository {
  final DatabaseHelper _dbHelper;
  final Map<String, Set<String>> _inMemoryFallback = {};

  SqliteSubscriptionRepository({DatabaseHelper? dbHelper})
      : _dbHelper = dbHelper ?? DatabaseHelper.instance;

  String _cacheKey(String userId, String entityType) => '$userId:$entityType';

  @override
  Future<Set<String>> getSubscribedEntityIds({
    required String userId,
    required String entityType,
  }) async {
    try {
      final ids = await _dbHelper.getSubscribedEntityIds(
        userId: userId,
        entityType: entityType,
      );
      final set = ids.toSet();
      _inMemoryFallback[_cacheKey(userId, entityType)] = set;
      return set;
    } catch (_) {
      return _inMemoryFallback[_cacheKey(userId, entityType)] ?? <String>{};
    }
  }

  @override
  Future<void> addSubscription({
    required String userId,
    required String entityType,
    required String entityId,
  }) async {
    final key = _cacheKey(userId, entityType);
    final set = _inMemoryFallback.putIfAbsent(key, () => <String>{});
    set.add(entityId);

    try {
      await _dbHelper.insertSubscription(
        userId: userId,
        entityType: entityType,
        entityId: entityId,
      );
    } catch (_) {}
  }

  @override
  Future<void> removeSubscription({
    required String userId,
    required String entityType,
    required String entityId,
  }) async {
    final key = _cacheKey(userId, entityType);
    final set = _inMemoryFallback[key];
    set?.remove(entityId);

    try {
      await _dbHelper.deleteSubscription(
        userId: userId,
        entityType: entityType,
        entityId: entityId,
      );
    } catch (_) {}
  }

  @override
  Future<bool> isSubscribed({
    required String userId,
    required String entityType,
    required String entityId,
  }) async {
    final set = await getSubscribedEntityIds(userId: userId, entityType: entityType);
    return set.contains(entityId);
  }

  @override
  Future<void> clearUserSubscriptions(String userId) async {
    _inMemoryFallback.remove(_cacheKey(userId, 'league'));
    _inMemoryFallback.remove(_cacheKey(userId, 'tournament'));

    try {
      await _dbHelper.clearSubscriptionsForUser(userId);
    } catch (_) {}
  }
}

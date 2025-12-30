import 'dart:convert';

import 'package:example/src/shop/model/product.dart';
import 'package:example/src/shop/model/recommendation.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// {@template recommendation_repository}
/// Repository for persisting and retrieving recommendation data
/// {@endtemplate}
abstract class IRecommendationRepository {
  /// Save a recommendation set
  Future<void> saveRecommendationSet(RecommendationSet set);

  /// Retrieve a cached recommendation set
  Future<RecommendationSet?> getRecommendationSet({
    required RecommendationContext context,
    ProductID? sourceProductId,
  });

  /// Clear all cached recommendations
  Future<void> clearAllRecommendations();

  /// Clear expired recommendations
  Future<void> clearExpiredRecommendations();

  /// Save user interaction for algorithm training
  Future<void> recordInteraction({
    required ProductID productId,
    required String interactionType,
    DateTime? timestamp,
  });

  /// Get user interaction history
  Future<Map<String, List<Map<String, Object?>>>> getInteractionHistory();

  /// Clear interaction history older than duration
  Future<void> pruneInteractionHistory(Duration maxAge);
}

extension type RecommendationInteractionType(String value) {
  static const view = 'view';
  static const click = 'click';
  static const addToCart = 'add_to_cart';
  static const addToFavorite = 'add_to_favorite';
  static const removeFromCart = 'remove_from_cart';
  static const purchase = 'purchase';

  static const all = [
    view,
    click,
    addToCart,
    addToFavorite,
    removeFromCart,
    purchase,
  ];
}

/// {@template recommendation_repository_impl}
/// Implementation of recommendation repository using SharedPreferences
/// {@endtemplate}
class RecommendationRepositoryImpl implements IRecommendationRepository {
  /// {@macro recommendation_repository_impl}
  RecommendationRepositoryImpl({required SharedPreferencesWithCache prefs})
    : _prefs = prefs;
  final SharedPreferencesWithCache _prefs;

  static const String _recommendationsPrefix = 'recommendations.cache';
  static const String _interactionsKey = 'recommendations.interactions';

  String _getCacheKey({
    required RecommendationContext context,
    ProductID? sourceProductId,
  }) {
    final base = '$_recommendationsPrefix.${context.name}';
    return sourceProductId != null ? '$base.$sourceProductId' : base;
  }

  @override
  Future<void> saveRecommendationSet(RecommendationSet set) async {
    final key = _getCacheKey(
      context: set.context,
      sourceProductId: set.sourceProductId,
    );

    final data = _serializeRecommendationSet(set);
    await _prefs.setString(key, jsonEncode(data));
  }

  @override
  Future<RecommendationSet?> getRecommendationSet({
    required RecommendationContext context,
    ProductID? sourceProductId,
  }) async {
    final key = _getCacheKey(
      context: context,
      sourceProductId: sourceProductId,
    );

    final jsonStr = _prefs.getString(key);
    if (jsonStr == null) return null;

    try {
      final data = jsonDecode(jsonStr) as Map<String, Object?>;
      final set = _deserializeRecommendationSet(data);

      // Check if expired
      if (set.isExpired) {
        await _prefs.remove(key);
        return null;
      }

      return set;
    } on Object {
      // Invalid cache data, clear it
      await _prefs.remove(key);
      return null;
    }
  }

  @override
  Future<void> clearAllRecommendations() async {
    final keys = _prefs.keys;
    final recommendationKeys = keys.where(
      (k) => k.startsWith(_recommendationsPrefix),
    );

    await Future.wait(recommendationKeys.map(_prefs.remove));
  }

  @override
  Future<void> clearExpiredRecommendations() async {
    final keys = _prefs.keys;
    final recommendationKeys = keys
        .where((k) => k.startsWith(_recommendationsPrefix))
        .toList();

    for (final key in recommendationKeys) {
      final jsonStr = _prefs.getString(key);
      if (jsonStr == null) continue;

      try {
        final data = jsonDecode(jsonStr) as Map<String, Object?>;
        final set = _deserializeRecommendationSet(data);

        if (set.isExpired) {
          await _prefs.remove(key);
        }
      } on Object {
        // Invalid data, remove it
        await _prefs.remove(key);
      }
    }
  }

  @override
  Future<void> recordInteraction({
    required ProductID productId,
    required String interactionType,
    DateTime? timestamp,
  }) async {
    final history = await getInteractionHistory();
    final typeHistory = history[interactionType] ?? []
      ..add({
        'productId': productId,
        'timestamp': (timestamp ?? DateTime.now()).toIso8601String(),
      });

    // Keep only last 100 interactions per type
    final limited = typeHistory.length > 100
        ? typeHistory.sublist(typeHistory.length - 100)
        : typeHistory;

    history[interactionType] = limited;

    await _prefs.setString(_interactionsKey, jsonEncode(history));
  }

  @override
  Future<Map<String, List<Map<String, Object?>>>>
  getInteractionHistory() async {
    final jsonStr = _prefs.getString(_interactionsKey);
    if (jsonStr == null) return {};

    try {
      final data = jsonDecode(jsonStr) as Map<String, Object?>;
      return data.map((key, value) {
        final list = (value as List<Object?>)
            .whereType<Map<String, Object?>>()
            .toList();
        return MapEntry(key, list);
      });
    } on Object {
      return {};
    }
  }

  @override
  Future<void> pruneInteractionHistory(Duration maxAge) async {
    final history = await getInteractionHistory();
    final cutoff = DateTime.now().subtract(maxAge);
    var modified = false;

    for (final entry in history.entries) {
      final filtered = entry.value.where((item) {
        final timestampStr = item['timestamp'] as String?;
        if (timestampStr == null) return false;

        try {
          final timestamp = DateTime.parse(timestampStr);
          return timestamp.isAfter(cutoff);
        } on Object {
          return false;
        }
      }).toList();

      if (filtered.length != entry.value.length) {
        history[entry.key] = filtered;
        modified = true;
      }
    }

    if (modified) {
      await _prefs.setString(_interactionsKey, jsonEncode(history));
    }
  }

  Map<String, Object?> _serializeRecommendationSet(RecommendationSet set) => {
    'context': set.context.name,
    'sourceProductId': set.sourceProductId,
    'generatedAt': set.generatedAt.toIso8601String(),
    'expiresAt': set.expiresAt?.toIso8601String(),
    'metadata': set.metadata,
    'recommendations': set.recommendations
        .map(
          (r) => {
            'productId': r.productId,
            'score': r.score,
            'strategy': r.strategy.name,
            'quality': r.quality.name,
            'reason': r.reason,
            'metadata': r.metadata,
          },
        )
        .toList(),
  };

  RecommendationSet _deserializeRecommendationSet(Map<String, Object?> data) {
    final contextName = data['context'] as String;
    final context = RecommendationContext.values.firstWhere(
      (c) => c.name == contextName,
    );

    final recommendationsData = (data['recommendations'] as List<Object?>)
        .whereType<Map<String, Object?>>()
        .toList();

    final recommendations = recommendationsData.map((r) {
      final strategyName = r['strategy'] as String;
      final strategy = RecommendationStrategy.values.firstWhere(
        (s) => s.name == strategyName,
      );

      final qualityName = r['quality'] as String;
      final quality = RecommendationQuality.values.firstWhere(
        (q) => q.name == qualityName,
      );

      return RecommendationResult(
        productId: r['productId'] as ProductID,
        score: (r['score'] as num).toDouble(),
        strategy: strategy,
        quality: quality,
        reason: r['reason'] as String,
        metadata: (r['metadata'] as Map<String, Object?>?) ?? {},
      );
    }).toList();

    return RecommendationSet(
      context: context,
      recommendations: recommendations,
      generatedAt: DateTime.parse(data['generatedAt'] as String),
      sourceProductId: data['sourceProductId'] as ProductID?,
      expiresAt: data['expiresAt'] != null
          ? DateTime.parse(data['expiresAt'] as String)
          : null,
      metadata: (data['metadata'] as Map<String, Object?>?) ?? {},
    );
  }
}

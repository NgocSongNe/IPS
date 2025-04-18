import 'package:flutter_cache_manager/flutter_cache_manager.dart';

class CustomCacheManager {
  static const cacheKey = 'customCache';
  
  static final CustomCacheManager instance = CustomCacheManager._();

  CustomCacheManager._();

  CacheManager get cacheManager {
    return CacheManager(
      Config(
        cacheKey,
        stalePeriod: const Duration(days: 7), // Thời gian hết hạn của bộ nhớ cache
        maxNrOfCacheObjects: 100, // Số lượng đối tượng cache tối đa
      ),
    );
  }
}

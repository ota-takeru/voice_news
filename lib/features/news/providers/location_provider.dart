import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/location_model.dart';
import '../services/location_service.dart';

final locationServiceProvider = Provider((ref) => LocationService());

final locationProvider =
    StateNotifierProvider<LocationNotifier, AsyncValue<Location>>((ref) {
  final locationService = ref.watch(locationServiceProvider);
  return LocationNotifier(locationService);
});

class LocationNotifier extends StateNotifier<AsyncValue<Location>> {
  final LocationService _locationService;
  final int maxRetries = 1;
  final Duration retryDelay = const Duration(seconds: 2);

  LocationNotifier(this._locationService) : super(const AsyncValue.loading()) {
    fetchLocation();
  }

  Future<void> fetchLocation() async {
    state = const AsyncValue.loading();
    for (int i = 0; i < maxRetries; i++) {
      try {
        final locationData = await _locationService.getLocationFromIP().timeout(
              const Duration(seconds: 3),
              onTimeout: () =>
                  throw TimeoutException('Location fetch timed out'),
            );
        final location = Location(
          city: locationData['city'] as String,
          country: locationData['country'] as String,
          latitude: locationData['latitude'] as double,
          longitude: locationData['longitude'] as double,
        );
        state = AsyncValue.data(location);
        return;
      } catch (e) {
        if (i == maxRetries - 1) {
          state = AsyncValue.error(_getErrorMessage(e), StackTrace.current);
        } else {
          await Future.delayed(retryDelay);
        }
      }
    }
  }
}

String _getErrorMessage(dynamic error) {
  if (error is TimeoutException) {
    return '位置情報の取得がタイムアウトしました。ネットワーク接続を確認してください。';
  } else if (error is Exception) {
    return 'エラーが発生しました。インターネット接続を確認し、しばらくしてからもう一度お試しください。';
  } else {
    return '位置情報の取得中に予期せぬエラーが発生しました。';
  }
}

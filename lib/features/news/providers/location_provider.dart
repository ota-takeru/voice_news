import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/location_model.dart';
import '../services/location_service.dart';

// LocationService Provider
final locationServiceProvider = Provider((ref) => LocationService());

// Location Provider
final locationProvider =
    StateNotifierProvider<LocationNotifier, AsyncValue<Location>>((ref) {
  final locationService = ref.watch(locationServiceProvider);
  return LocationNotifier(locationService);
});

class LocationNotifier extends StateNotifier<AsyncValue<Location>> {
  final LocationService _locationService;

  LocationNotifier(this._locationService) : super(const AsyncValue.loading());

  Future<void> fetchLocation() async {
    state = const AsyncValue.loading();
    try {
      final locationData = await _locationService.getLocationFromIP();
      final location = Location(
        city: locationData['city'] as String,
        country: locationData['country'] as String,
        latitude: locationData['latitude'] as double,
        longitude: locationData['longitude'] as double,
      );
      print(location);
      state = AsyncValue.data(location);
    } catch (e, stackTrace) {
      state = AsyncValue.error(e, stackTrace);
    }
  }
}

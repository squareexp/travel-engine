import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'api_client.dart';
import 'models.dart';

class CatalogRepository {
  CatalogRepository(this._api);
  final ApiClient _api;

  Future<List<Destination>> listDestinations({String? country}) async {
    final resp = await _api.dio.get(
      '/destinations',
      queryParameters: {'country': ?country, 'limit': 20},
    );
    final data = (resp.data['data'] as List).cast<Map<String, dynamic>>();
    return data.map(Destination.fromJson).toList();
  }

  Future<List<Listing>> listListings({
    String? type,
    String? destinationId,
    String? search,
    int limit = 12,
    int offset = 0,
  }) async {
    final resp = await _api.dio.get(
      '/listings',
      queryParameters: {
        'type': ?type,
        'destination_id': ?destinationId,
        if (search != null && search.isNotEmpty) 'search': search,
        'limit': limit,
        'offset': offset,
      },
    );
    final raw = resp.data;
    final list = raw is Map && raw['data'] is List
        ? (raw['data'] as List)
        : (raw is List ? raw : const []);
    return list.cast<Map<String, dynamic>>().map(Listing.fromJson).toList();
  }

  Future<Listing> getListing(String id) async {
    final resp = await _api.dio.get('/listings/$id');
    return Listing.fromJson(resp.data as Map<String, dynamic>);
  }
}

class BookingsRepository {
  BookingsRepository(this._api);
  final ApiClient _api;

  Future<List<Booking>> myBookings() async {
    final resp = await _api.dio.get('/bookings');
    final list = (resp.data is Map && resp.data['data'] is List)
        ? (resp.data['data'] as List)
        : (resp.data as List? ?? const []);
    return list.cast<Map<String, dynamic>>().map(Booking.fromJson).toList();
  }

  Future<Booking> createBooking({
    required String listingId,
    required String travelDate,
    required int guests,
    String? specialRequests,
  }) async {
    final resp = await _api.dio.post(
      '/bookings',
      data: {
        'listing_id': listingId,
        'travel_date': travelDate,
        'guests': guests,
        'special_requests': ?specialRequests,
      },
    );
    return Booking.fromJson(resp.data as Map<String, dynamic>);
  }
}

class TransportRepository {
  TransportRepository(this._api);
  final ApiClient _api;

  Future<List<Map<String, dynamic>>> listCars() async {
    final resp = await _api.dio.get('/transport/cars');
    final raw = resp.data;
    final list = raw is Map && raw['data'] is List
        ? (raw['data'] as List)
        : (raw is List ? raw : const []);
    return list.cast<Map<String, dynamic>>();
  }

  Future<Map<String, dynamic>> calculateFare(Map<String, dynamic> body) async {
    final resp = await _api.dio.post('/transport/calculate-fare', data: body);
    return resp.data as Map<String, dynamic>;
  }
}

final catalogRepoProvider = Provider<CatalogRepository>(
  (ref) => CatalogRepository(ref.watch(apiClientProvider)),
);
final bookingsRepoProvider = Provider<BookingsRepository>(
  (ref) => BookingsRepository(ref.watch(apiClientProvider)),
);
final transportRepoProvider = Provider<TransportRepository>(
  (ref) => TransportRepository(ref.watch(apiClientProvider)),
);

final destinationsProvider = FutureProvider<List<Destination>>((ref) async {
  final repo = ref.watch(catalogRepoProvider);
  try {
    return await repo.listDestinations();
  } catch (_) {
    return const [];
  }
});

final featuredListingsProvider = FutureProvider<List<Listing>>((ref) async {
  final repo = ref.watch(catalogRepoProvider);
  try {
    return await repo.listListings(limit: 12);
  } catch (_) {
    return const [];
  }
});

final listingDetailProvider = FutureProvider.family<Listing, String>((
  ref,
  id,
) async {
  return ref.watch(catalogRepoProvider).getListing(id);
});

final myBookingsProvider = FutureProvider<List<Booking>>((ref) async {
  try {
    return await ref.watch(bookingsRepoProvider).myBookings();
  } catch (_) {
    return const [];
  }
});

class SearchQuery {
  const SearchQuery({this.type, this.text, this.destinationId});
  final String? type;
  final String? text;
  final String? destinationId;

  @override
  bool operator ==(Object other) =>
      other is SearchQuery &&
      other.type == type &&
      other.text == text &&
      other.destinationId == destinationId;
  @override
  int get hashCode => Object.hash(type, text, destinationId);
}

final searchResultsProvider = FutureProvider.autoDispose
    .family<List<Listing>, SearchQuery>((ref, q) async {
      return ref
          .watch(catalogRepoProvider)
          .listListings(
            type: q.type,
            search: q.text,
            destinationId: q.destinationId,
            limit: 30,
          );
    });

final carsProvider = FutureProvider<List<Map<String, dynamic>>>((ref) async {
  try {
    return await ref.watch(transportRepoProvider).listCars();
  } catch (_) {
    return const [];
  }
});

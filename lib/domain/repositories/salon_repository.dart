import '../entities/salon.dart';

/// Contract for fetching vendors. The MVP ships an in-memory mock
/// implementation; a REST/GraphQL implementation can replace it without
/// touching the presentation layer.
abstract interface class SalonRepository {
  Future<List<Salon>> getSalons();

  Future<Salon> getSalonById(String id);
}

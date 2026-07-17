import '../../domain/entities/salon.dart';
import '../../domain/repositories/salon_repository.dart';
import '../mock/mock_salons.dart';

/// In-memory implementation with simulated network latency so the UI's
/// loading states are exercised like they would be against a real API.
class MockSalonRepository implements SalonRepository {
  static const _latency = Duration(milliseconds: 450);

  @override
  Future<List<Salon>> getSalons() async {
    await Future<void>.delayed(_latency);
    return List.unmodifiable(mockSalons);
  }

  @override
  Future<Salon> getSalonById(String id) async {
    await Future<void>.delayed(_latency);
    return mockSalons.firstWhere(
      (s) => s.id == id,
      orElse: () => throw StateError('Salon not found: $id'),
    );
  }
}

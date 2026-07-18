import '../../domain/entities/salon.dart';
import '../../domain/repositories/salon_repository.dart';
import '../api/api_client.dart';
import '../api/api_mappers.dart';

/// [SalonRepository] backed by the beautyhub-api service.
class ApiSalonRepository implements SalonRepository {
  ApiSalonRepository(this._client);

  final ApiClient _client;

  @override
  Future<List<Salon>> getSalons() async {
    final json = await _client.get('/salons') as List<dynamic>;
    return json.map((s) => ApiMappers.salon(s as Map<String, dynamic>)).toList();
  }

  @override
  Future<Salon> getSalonById(String id) async {
    final json = await _client.get('/salons/$id') as Map<String, dynamic>;
    return ApiMappers.salon(json);
  }
}

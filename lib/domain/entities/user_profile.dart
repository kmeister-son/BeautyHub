/// The signed-in (or guest) identity behind the current session.
class UserProfile {
  const UserProfile({
    required this.id,
    required this.email,
    required this.name,
    required this.isGuest,
  });

  final String id;
  final String email;
  final String name;

  /// Guests are auto-provisioned per install; they own bookings but have
  /// no credentials. Signing in/up replaces the guest identity.
  final bool isGuest;
}

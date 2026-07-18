import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/di/providers.dart';
import '../../../core/theme/theme_mode_provider.dart';
import '../../../domain/entities/user_profile.dart';
import '../../auth/presentation/providers/auth_providers.dart';
import '../../bookings/presentation/providers/bookings_providers.dart';

/// Account area: identity card (guest or signed in), appearance, and
/// placeholders for payments/addresses/favourites (post-MVP).
class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  void _comingSoon(BuildContext context, String feature) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text('$feature is coming soon')));
  }

  Future<void> _signOut(BuildContext context, WidgetRef ref) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Sign out?'),
        content: const Text(
            'You will continue as a guest. Bookings made while signed '
            'in stay with your account.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Sign out'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    await ref.read(authRepositoryProvider).signOut();
    // The identity changed, so everything it owns must reload.
    ref.invalidate(currentUserProvider);
    ref.invalidate(bookingsProvider);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final scheme = Theme.of(context).colorScheme;
    final themeMode = ref.watch(themeModeProvider);
    final user = ref.watch(currentUserProvider).valueOrNull;
    final isSignedIn = user != null && !user.isGuest;
    return Scaffold(
      appBar: AppBar(title: const Text('Profile')),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          _IdentityCard(user: user),
          const SizedBox(height: 14),
          Card(
            child: Column(
              children: [
                _MenuTile(
                  icon: Icons.credit_card_rounded,
                  label: 'Payment methods',
                  onTap: () => _comingSoon(context, 'Payments'),
                ),
                const Divider(indent: 56),
                _MenuTile(
                  icon: Icons.place_outlined,
                  label: 'Saved addresses',
                  onTap: () => _comingSoon(context, 'Addresses'),
                ),
                const Divider(indent: 56),
                _MenuTile(
                  icon: Icons.favorite_outline_rounded,
                  label: 'Favourite salons',
                  onTap: () => _comingSoon(context, 'Favourites'),
                ),
                const Divider(indent: 56),
                _MenuTile(
                  icon: Icons.notifications_outlined,
                  label: 'Notifications',
                  onTap: () => _comingSoon(context, 'Notifications'),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          Card(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.dark_mode_outlined, color: scheme.primary),
                      const SizedBox(width: 14),
                      const Text(
                        'Appearance',
                        style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14.5),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  SizedBox(
                    width: double.infinity,
                    child: SegmentedButton<ThemeMode>(
                      segments: const [
                        ButtonSegment(value: ThemeMode.system, label: Text('System')),
                        ButtonSegment(value: ThemeMode.light, label: Text('Light')),
                        ButtonSegment(value: ThemeMode.dark, label: Text('Dark')),
                      ],
                      selected: {themeMode},
                      showSelectedIcon: false,
                      onSelectionChanged: (selection) =>
                          ref.read(themeModeProvider.notifier).state = selection.first,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 14),
          Card(
            child: Column(
              children: [
                _MenuTile(
                  icon: Icons.help_outline_rounded,
                  label: 'Help & support',
                  onTap: () => _comingSoon(context, 'Support'),
                ),
                const Divider(indent: 56),
                _MenuTile(
                  icon: Icons.description_outlined,
                  label: 'Terms & privacy',
                  onTap: () => _comingSoon(context, 'Terms & privacy'),
                ),
                if (isSignedIn) ...[
                  const Divider(indent: 56),
                  _MenuTile(
                    icon: Icons.logout_rounded,
                    label: 'Sign out',
                    onTap: () => _signOut(context, ref),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: 24),
          Center(
            child: Text(
              'BeautyHub v0.1.0 · MVP',
              style: TextStyle(fontSize: 12.5, color: scheme.onSurfaceVariant),
            ),
          ),
        ],
      ),
    );
  }
}

/// Header card: greets the signed-in user, or invites a guest to sign in.
class _IdentityCard extends StatelessWidget {
  const _IdentityCard({required this.user});

  /// Null while the profile is still loading.
  final UserProfile? user;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final isSignedIn = user != null && !user!.isGuest;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          children: [
            Row(
              children: [
                CircleAvatar(
                  radius: 30,
                  backgroundColor: scheme.primary.withValues(alpha: 0.12),
                  child: Icon(Icons.person_outline_rounded,
                      size: 32, color: scheme.primary),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        isSignedIn ? user!.name : 'Guest',
                        style: const TextStyle(
                            fontSize: 17, fontWeight: FontWeight.w800),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        isSignedIn
                            ? user!.email
                            : 'Sign in to sync your bookings',
                        style: TextStyle(
                            fontSize: 13, color: scheme.onSurfaceVariant),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            if (!isSignedIn) ...[
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: FilledButton(
                      style: FilledButton.styleFrom(
                          minimumSize: const Size.fromHeight(46)),
                      onPressed: () => context.push('/login'),
                      child: const Text('Sign in',
                          style: TextStyle(fontSize: 14.5)),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: OutlinedButton(
                      style: OutlinedButton.styleFrom(
                        minimumSize: const Size.fromHeight(46),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16)),
                      ),
                      onPressed: () => context.push('/signup'),
                      child: const Text('Create account',
                          style: TextStyle(fontSize: 14.5)),
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _MenuTile extends StatelessWidget {
  const _MenuTile({required this.icon, required this.label, required this.onTap});

  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return ListTile(
      leading: Icon(icon, color: scheme.primary),
      title: Text(label, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14.5)),
      trailing: Icon(Icons.chevron_right_rounded, color: scheme.onSurfaceVariant),
      onTap: onTap,
    );
  }
}

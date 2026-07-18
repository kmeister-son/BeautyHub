/// Field validators shared by the login and sign-up forms. Password rules
/// mirror the API's RegisterDto (min 8 characters).
String? validateEmail(String? value) {
  final v = value?.trim() ?? '';
  if (v.isEmpty) return 'Enter your email';
  if (!RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(v)) {
    return 'Enter a valid email address';
  }
  return null;
}

String? validateNewPassword(String? value) {
  if (value == null || value.isEmpty) return 'Choose a password';
  if (value.length < 8) return 'Use at least 8 characters';
  return null;
}

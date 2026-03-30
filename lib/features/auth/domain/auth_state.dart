class AuthState {
  final bool isAuthenticated;
  final String? username;
  final bool isAdmin;

  const AuthState({
    required this.isAuthenticated,
    this.username,
    this.isAdmin = false,
  });

  const AuthState.unauthenticated()
    : this(isAuthenticated: false, isAdmin: false);

  const AuthState.authenticated(String username, {bool isAdmin = false})
    : this(isAuthenticated: true, username: username, isAdmin: isAdmin);
}

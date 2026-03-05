class AuthState {
  final bool isAuthenticated;
  final String? username;

  const AuthState({
    required this.isAuthenticated,
    this.username,
  });

  const AuthState.unauthenticated() : this(isAuthenticated: false);

  const AuthState.authenticated(String username)
      : this(isAuthenticated: true, username: username);
}
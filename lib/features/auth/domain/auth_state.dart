class AuthState {
  final bool isAuthenticated;
  final String? username;
  final bool isAdmin;
  final bool isFirstLogin;

  const AuthState({
    required this.isAuthenticated,
    this.username,
    this.isAdmin = false,
    this.isFirstLogin = false,
  });

  const AuthState.unauthenticated()
    : this(isAuthenticated: false, isAdmin: false, isFirstLogin: false);

  const AuthState.authenticated(
    String username, {
    bool isAdmin = false,
    bool isFirstLogin = false,
  }) : this(
         isAuthenticated: true,
         username: username,
         isAdmin: isAdmin,
         isFirstLogin: isFirstLogin,
       );
}

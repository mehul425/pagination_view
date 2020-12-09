class User {
  User(this.name, this.email);

  final String name;
  final String email;

  User copyWith({String name, String email}) {
    return User(name ?? this.name, email ?? this.email);
  }
}

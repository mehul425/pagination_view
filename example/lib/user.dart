class User {
  User(this.name, this.email);

  final String name;
  final String email;

  User copyWith({String name, String email}) {
    return User(name ?? this.name, email ?? this.email);
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is User &&
          runtimeType == other.runtimeType &&
          name == other.name &&
          email == other.email;

  @override
  int get hashCode => name.hashCode ^ email.hashCode;
}

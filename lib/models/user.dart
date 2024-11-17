class User {
  final int? id;
  final String email;
  final String password;
  final String username; // Add username field

  User({
    this.id,
    required this.email,
    required this.password,
    required this.username,  // Add username to the constructor
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'email': email,
      'password': password,
      'username': username, // Save username in the database
    };
  }

  factory User.fromMap(Map<String, dynamic> map) {
    return User(
      id: map['id'] as int?,
      email: map['email'] as String,
      password: map['password'] as String,
      username: map['username'] as String, // Fetch username from database
    );
  }
}

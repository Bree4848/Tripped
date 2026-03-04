class User {
  final String id;
  final String name;
  final String email;
  final String role; // 'resident', 'electrician', or 'admin'

  User({required this.id, required this.name, required this.email, required this.role});

  // This "factory" converts the JSON from your Node.js API into a Flutter Object
  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['_id'],
      name: json['name'],
      email: json['email'],
      role: json['role'],
    );
  }
}
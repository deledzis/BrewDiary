class User {
  final int? id;
  final String email;
  final String password;
  final String? nickname;
  final DateTime createdDate;

  User({
    this.id,
    required this.email,
    required this.password,
    this.nickname,
    required this.createdDate,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'email': email,
      'password': password,
      'nickname': nickname,
      'created_date': createdDate.toIso8601String(),
    };
  }

  factory User.fromMap(Map<String, dynamic> map) {
    return User(
      id: map['id'] as int?,
      email: map['email'] as String,
      password: map['password'] as String,
      nickname: map['nickname'] as String?,
      createdDate: DateTime.parse(map['created_date'] as String),
    );
  }
}

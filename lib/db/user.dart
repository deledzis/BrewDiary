import 'dart:convert';
import 'dart:math';
import 'package:crypto/crypto.dart';

class User {
  final int id;
  final String email;
  final String _passwordHash;
  final String? nickname;
  final DateTime createdDate;

  User({
    required this.id,
    required this.email,
    required String passwordHash,
    this.nickname,
    required this.createdDate,
  }) : _passwordHash = passwordHash;

  // Static method to create a User with a plain text password
  static User withPlainPassword({
    required int id,
    required String email,
    required String plainPassword,
    String? nickname,
    required DateTime createdDate,
  }) {
    return User(
      id: id,
      email: email,
      passwordHash: _hashPassword(plainPassword),
      nickname: nickname,
      createdDate: createdDate,
    );
  }

  // Generate a secure password hash with salt
  static String _hashPassword(String password) {
    // Generate a random salt
    final salt = _generateSalt();
    // Combine password and salt, then hash
    final bytes = utf8.encode(password + salt);
    final digest = sha256.convert(bytes);
    // Store as salt + hash for verification
    return salt + digest.toString();
  }

  // Generate a random salt
  static String _generateSalt() {
    final random = Random.secure();
    final saltBytes = List<int>.generate(16, (i) => random.nextInt(256));
    return base64Encode(saltBytes);
  }

  // Verify a plain text password against the stored hash
  bool verifyPassword(String plainPassword) {
    if (_passwordHash.length < 24) return false; // Invalid hash format
    
    final salt = _passwordHash.substring(0, 24); // Extract salt (base64 encoded 16 bytes = 24 chars)
    final storedHash = _passwordHash.substring(24);
    
    // Hash the provided password with the stored salt
    final bytes = utf8.encode(plainPassword + salt);
    final digest = sha256.convert(bytes);
    
    return digest.toString() == storedHash;
  }

  // Get the password hash (for database storage)
  String get passwordHash => _passwordHash;

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'email': email,
      'password_hash': _passwordHash, // Store the hash, not plain text
      'nickname': nickname,
      'created_date': createdDate.toIso8601String(),
    };
  }

  factory User.fromMap(Map<String, dynamic> map) {
    return User(
      id: map['id'] as int,
      email: map['email'] as String,
      passwordHash: map['password_hash'] as String, // This is now a hash
      nickname: map['nickname'] as String?,
      createdDate: DateTime.parse(map['created_date'] as String),
    );
  }
}

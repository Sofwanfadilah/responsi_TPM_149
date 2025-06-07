import 'dart:convert';

class User {
  final String id;
  final String username;
  final String password;
  final String name;
  final int age;
  final String country;
  final String? preferredCurrency;
  final String? photoUrl; 

  User({
    required this.id,
    required this.username,
    required this.password,
    required this.name,
    required this.age,
    required this.country,
    this.preferredCurrency,
    this.photoUrl,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'username': username,
      'password': password,
      'name': name,
      'age': age,
      'country': country,
      'preferred_currency': preferredCurrency,
      'photo_url': photoUrl,
    };
  }

  factory User.fromMap(Map<String, dynamic> map) {
    return User(
      id: map['id'] as String,
      username: map['username'] as String,
      password: map['password'] as String,
      name: map['name'] as String? ?? '',
      age: map['age'] as int? ?? 0,
      country: map['country'] as String? ?? '',
      preferredCurrency: map['preferred_currency'] as String?,
      photoUrl: map['photo_url'] as String?,
    );
  }

  User copyWith({
    String? name,
    int? age,
    String? country,
    String? preferredCurrency,
    String? photoUrl,
  }) {
    return User(
      id: id,
      username: username,
      password: password,
      name: name ?? this.name,
      age: age ?? this.age,
      country: country ?? this.country,
      preferredCurrency: preferredCurrency ?? this.preferredCurrency,
      photoUrl: photoUrl ?? this.photoUrl,
    );
  }
}

class User {
  final int? id;
  final String email;
  final String password;
  final String name; 
  final String? bluetoothName;
  final String bluetoothIdentifier; 

  User({
    this.id,
    required this.email,
    required this.password,
    required this.name,
    this.bluetoothName,
    required this.bluetoothIdentifier,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'email': email,
      'password': password,
      'name': name,
      'bluetoothName': bluetoothName,
      'bluetoothIdentifier': bluetoothIdentifier,
    };
  }

  factory User.fromMap(Map<String, dynamic> map) {
    return User(
      id: map['id'],
      email: map['email'],
      password: map['password'],
      name: map['name'],
      bluetoothName: map['bluetoothName'],
      bluetoothIdentifier: map['bluetoothIdentifier'],
    );
  }
}
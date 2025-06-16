class Salesman {
  final int id;
  final String name;
  final String? phone;
  final String? email;

  Salesman({required this.id, required this.name, this.phone, this.email});

  factory Salesman.fromJson(Map<String, dynamic> json) {
    return Salesman(
      id: json['id'],
      name: json['name'],
      phone: json['phone'],
      email: json['email'],
    );
  }

  Map<String, dynamic> toJson() {
    return {'id': id, 'name': name, 'phone': phone, 'email': email};
  }
}

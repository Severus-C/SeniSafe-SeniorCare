class User {
  const User({
    required this.id,
    required this.name,
    required this.age,
    required this.bloodType,
    required this.primaryContactName,
    required this.primaryContactPhone,
    required this.chronicConditions,
    required this.allergies,
  });

  final String id;
  final String name;
  final int age;
  final String bloodType;
  final String primaryContactName;
  final String primaryContactPhone;
  final List<String> chronicConditions;
  final List<String> allergies;

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'id': id,
      'name': name,
      'age': age,
      'bloodType': bloodType,
      'primaryContactName': primaryContactName,
      'primaryContactPhone': primaryContactPhone,
      'chronicConditions': chronicConditions,
      'allergies': allergies,
    };
  }
}

import 'dart:io';

class Pet {
  final String name;
  final String type; // 강아지, 고양이
  final String species;
  final String age;
  final String height;
  final String weight;
  final String? gender;
  final bool? isNeutered;
  String activityLevel;
  final File? imageFile; // File 이미지
  final String? imageAsset; // Asset 이미지 (필요시)

  Pet({
    required this.name,
    this.type = "강아지",
    this.species = "",
    this.age = "",
    this.height = "",
    this.weight = "",
    this.gender,
    this.isNeutered,
    this.activityLevel = "보통",
    this.imageFile,
    this.imageAsset,
  });

  // Map에서 객체로 변환 (기존 코드 호환용)
  factory Pet.fromMap(Map<String, dynamic> map) {
    return Pet(
      name: map['name'],
      type: map['type'] ?? "강아지",
      species: map['species'] ?? "",
      age: map['age'] ?? "",
      height: map['height'] ?? "",
      weight: map['weight'] ?? "",
      gender: map['gender'],
      isNeutered: map['isNeutered'],
      activityLevel: map['activityLevel'] ?? "보통",
      imageFile: map['image'] is File ? map['image'] : null,
      imageAsset: map['image'] is String ? map['image'] : null,
    );
  }

  // 객체에서 Map으로 변환
  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'type': type,
      'species': species,
      'age': age,
      'height': height,
      'weight': weight,
      'gender': gender,
      'isNeutered': isNeutered,
      'activityLevel': activityLevel,
      'image': imageFile ?? imageAsset,
    };
  }
}

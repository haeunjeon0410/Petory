import 'package:flutter/material.dart';
import '../models/pet_model.dart';

class PetProfileCard extends StatelessWidget {
  final Pet pet;
  final VoidCallback onEdit; // [추가] 수정 콜백
  final VoidCallback onDelete; // [추가] 삭제 콜백

  const PetProfileCard({
    super.key,
    required this.pet,
    required this.onEdit, // [추가]
    required this.onDelete, // [추가]
  });

  @override
  Widget build(BuildContext context) {
    String petTypeEmoji = pet.type == "강아지"
        ? "🐶"
        : (pet.type == "고양이" ? "🐱" : "🐾");

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.08),
            blurRadius: 12,
            spreadRadius: 2,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start, // [수정] 위쪽 정렬
        children: [
          // 1. 프로필 이미지
          Container(
            width: 76,
            height: 76,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.grey[200],
              image: _getProfileImage(),
            ),
            child: _getProfileImage() == null
                ? Icon(Icons.pets, size: 40, color: Colors.grey[400])
                : null,
          ),
          const SizedBox(width: 18),

          // 2. 텍스트 정보 (Expanded로 남은 공간 차지)
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      pet.name,
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF43403C),
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text(petTypeEmoji, style: const TextStyle(fontSize: 20)),
                  ],
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Text(
                      "${pet.species} • ${pet.age}살",
                      style: const TextStyle(color: Colors.black, fontSize: 13),
                    ),
                    const SizedBox(width: 6),
                    if (pet.gender == 'male')
                      const Icon(Icons.male, color: Colors.blue, size: 16)
                    else if (pet.gender == 'female')
                      const Icon(Icons.female, color: Colors.red, size: 16),
                  ],
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    _buildTag("${pet.height} cm", Colors.blue),
                    const SizedBox(width: 8),
                    _buildTag("${pet.weight} kg", Colors.red),
                  ],
                ),
              ],
            ),
          ),

          // [핵심 추가] 3. 점 세 개 메뉴 버튼 (수정/삭제)
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert, color: Colors.grey),
            color: Colors.white,
            elevation: 3,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            onSelected: (String value) {
              if (value == 'edit') onEdit();
              if (value == 'delete') onDelete();
            },
            itemBuilder: (BuildContext context) => <PopupMenuEntry<String>>[
              const PopupMenuItem<String>(
                value: 'edit',
                child: Row(
                  children: [
                    Icon(Icons.edit, color: Colors.blue, size: 20),
                    SizedBox(width: 10),
                    Text('수정', style: TextStyle(fontSize: 14)),
                  ],
                ),
              ),
              const PopupMenuItem<String>(
                value: 'delete',
                child: Row(
                  children: [
                    Icon(Icons.delete, color: Colors.red, size: 20),
                    SizedBox(width: 10),
                    Text('삭제', style: TextStyle(fontSize: 14)),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // (이미지 처리 함수와 _buildTag 함수는 기존과 동일하게 유지)
  DecorationImage? _getProfileImage() {
    /* ... 이전 코드와 동일 ... */
    if (pet.imageFile != null) {
      return DecorationImage(
        image: FileImage(pet.imageFile!),
        fit: BoxFit.cover,
      );
    } else if (pet.imageAsset != null && pet.imageAsset!.isNotEmpty) {
      if (pet.imageAsset!.startsWith('http')) {
        return DecorationImage(
          image: NetworkImage(pet.imageAsset!),
          fit: BoxFit.cover,
        );
      }
      return DecorationImage(
        image: AssetImage(pet.imageAsset!),
        fit: BoxFit.cover,
      );
    }
    return null;
  }

  Widget _buildTag(String text, Color bgColor) {
    /* ... 이전 코드와 동일 ... */
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: bgColor.withOpacity(0.4),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Text(
        text,
        style: const TextStyle(
          color: Colors.black87,
          fontSize: 11,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

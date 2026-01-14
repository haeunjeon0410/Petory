import 'package:flutter/material.dart';
import '../models/pet_model.dart';

class PetProfileCard extends StatefulWidget {
  final Pet pet;
  final VoidCallback onEdit; // [??] ?? ??
  final VoidCallback onDelete; // [??] ?? ??
  final ValueChanged<String>? onActivityChanged;

  const PetProfileCard({
    super.key,
    required this.pet,
    required this.onEdit, // [??]
    required this.onDelete, // [??]
    this.onActivityChanged,
  });

  @override
  State<PetProfileCard> createState() => _PetProfileCardState();
}

class _PetProfileCardState extends State<PetProfileCard> {
  late String _activityLevel;

  @override
  void initState() {
    super.initState();
    _activityLevel = widget.pet.activityLevel;
  }

  @override
  void didUpdateWidget(covariant PetProfileCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.pet.activityLevel != widget.pet.activityLevel) {
      _activityLevel = widget.pet.activityLevel;
    }
  }

  IconData _activityIcon(String level) {
    if (level == '??') return Icons.nightlight_round;
    if (level == '??') return Icons.bolt;
    return Icons.pets;
  }

  @override
  Widget build(BuildContext context) {
    String petTypeEmoji = widget.pet.type == "???"
        ? "??"
        : (widget.pet.type == "???" ? "??" : "??");

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
        crossAxisAlignment: CrossAxisAlignment.start, // [??] ?? ??
        children: [
          // 1. ??? ???
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

          // 2. ??? ?? (Expanded? ?? ?? ??)
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      widget.pet.name,
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF43403C),
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text(petTypeEmoji, style: const TextStyle(fontSize: 20)),
                    const SizedBox(width: 8),
                    PopupMenuButton<String>(
                      tooltip: '???',
                      onSelected: (value) {
                        setState(() => _activityLevel = value);
                        widget.pet.activityLevel = value;
                        widget.onActivityChanged?.call(value);
                      },
                      itemBuilder: (context) => const [
                        PopupMenuItem<String>(
                          value: '??',
                          child: Row(
                            children: [
                              Icon(Icons.nightlight_round, size: 18),
                              SizedBox(width: 8),
                              Text('??'),
                            ],
                          ),
                        ),
                        PopupMenuItem<String>(
                          value: '??',
                          child: Row(
                            children: [
                              Icon(Icons.pets, size: 18),
                              SizedBox(width: 8),
                              Text('??'),
                            ],
                          ),
                        ),
                        PopupMenuItem<String>(
                          value: '??',
                          child: Row(
                            children: [
                              Icon(Icons.bolt, size: 18),
                              SizedBox(width: 8),
                              Text('??'),
                            ],
                          ),
                        ),
                      ],
                      child: Container(
                        width: 28,
                        height: 28,
                        decoration: BoxDecoration(
                          color: const Color(0xFFE7E5E4),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        alignment: Alignment.center,
                        child: Icon(
                          _activityIcon(_activityLevel),
                          size: 16,
                          color: const Color(0xFF44403B),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Text(
                      "${widget.pet.species} ? ${widget.pet.age}?",
                      style: const TextStyle(color: Colors.black, fontSize: 13),
                    ),
                    const SizedBox(width: 6),
                    if (widget.pet.gender == 'male')
                      const Icon(Icons.male, color: Colors.blue, size: 16)
                    else if (widget.pet.gender == 'female')
                      const Icon(Icons.female, color: Colors.red, size: 16),
                  ],
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Builder(
                      builder: (context) {
                        double hVal =
                            double.tryParse(widget.pet.height) ?? 0.0;
                        String hText = hVal.toStringAsFixed(1);
                        return _buildTag("$hText cm", Colors.blue);
                      },
                    ),
                    const SizedBox(width: 8),
                    Builder(
                      builder: (context) {
                        double wVal =
                            double.tryParse(widget.pet.weight) ?? 0.0;
                        String wText = wVal.toStringAsFixed(2);
                        return _buildTag("$wText kg", Colors.red);
                      },
                    ),
                  ],
                ),
              ],
            ),
          ),

          // [?? ??] 3. ?? ?? ?? ?? (??/??)
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert, color: Colors.grey),
            color: Colors.white,
            elevation: 3,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            onSelected: (String value) {
              if (value == 'edit') widget.onEdit();
              if (value == 'delete') widget.onDelete();
            },
            itemBuilder: (BuildContext context) => <PopupMenuEntry<String>>[
              const PopupMenuItem<String>(
                value: 'edit',
                child: Row(
                  children: [
                    Icon(Icons.edit, color: Colors.blue, size: 20),
                    SizedBox(width: 10),
                    Text('??', style: TextStyle(fontSize: 14)),
                  ],
                ),
              ),
              const PopupMenuItem<String>(
                value: 'delete',
                child: Row(
                  children: [
                    Icon(Icons.delete, color: Colors.red, size: 20),
                    SizedBox(width: 10),
                    Text('??', style: TextStyle(fontSize: 14)),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  DecorationImage? _getProfileImage() {
    if (widget.pet.imageFile != null) {
      return DecorationImage(
        image: FileImage(widget.pet.imageFile!),
        fit: BoxFit.cover,
      );
    } else if (widget.pet.imageAsset != null &&
        widget.pet.imageAsset!.isNotEmpty) {
      if (widget.pet.imageAsset!.startsWith('http')) {
        return DecorationImage(
          image: NetworkImage(widget.pet.imageAsset!),
          fit: BoxFit.cover,
        );
      }
      return DecorationImage(
        image: AssetImage(widget.pet.imageAsset!),
        fit: BoxFit.cover,
      );
    }
    return null;
  }

  Widget _buildTag(String text, Color bgColor) {
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

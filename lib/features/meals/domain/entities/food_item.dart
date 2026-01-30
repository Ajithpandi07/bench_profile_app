import 'package:equatable/equatable.dart';

class FoodItem extends Equatable {
  final String id;
  final String name;
  final double calories;
  final double carbs;
  final double protein;
  final double fat;
  final String servingSize;
  final double quantity; // e.g. 1 serving

  final double sodium;
  final double potassium;
  final double dietaryFibre;
  final double sugars;
  final double vitaminA;
  final double vitaminC;
  final double calcium;
  final double iron;

  final DateTime? createdAt;

  const FoodItem({
    required this.id,
    required this.name,
    required this.calories,
    this.carbs = 0,
    this.protein = 0,
    this.fat = 0,
    this.servingSize = '1 serving',
    this.quantity = 1.0,
    this.sodium = 0,
    this.potassium = 0,
    this.dietaryFibre = 0,
    this.sugars = 0,
    this.vitaminA = 0,
    this.vitaminC = 0,
    this.calcium = 0,
    this.iron = 0,
    this.createdAt,
  });

  FoodItem copyWith({
    String? id,
    String? name,
    double? calories,
    double? carbs,
    double? protein,
    double? fat,
    String? servingSize,
    double? quantity,
    double? sodium,
    double? potassium,
    double? dietaryFibre,
    double? sugars,
    double? vitaminA,
    double? vitaminC,
    double? calcium,
    double? iron,
    DateTime? createdAt,
  }) {
    return FoodItem(
      id: id ?? this.id,
      name: name ?? this.name,
      calories: calories ?? this.calories,
      carbs: carbs ?? this.carbs,
      protein: protein ?? this.protein,
      fat: fat ?? this.fat,
      servingSize: servingSize ?? this.servingSize,
      quantity: quantity ?? this.quantity,
      sodium: sodium ?? this.sodium,
      potassium: potassium ?? this.potassium,
      dietaryFibre: dietaryFibre ?? this.dietaryFibre,
      sugars: sugars ?? this.sugars,
      vitaminA: vitaminA ?? this.vitaminA,
      vitaminC: vitaminC ?? this.vitaminC,
      calcium: calcium ?? this.calcium,
      iron: iron ?? this.iron,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'calories': calories,
      'carbs': carbs,
      'protein': protein,
      'fat': fat,
      'servingSize': servingSize,
      'quantity': quantity,
      'sodium': sodium,
      'potassium': potassium,
      'dietaryFibre': dietaryFibre,
      'sugars': sugars,
      'vitaminA': vitaminA,
      'vitaminC': vitaminC,
      'calcium': calcium,
      'iron': iron,
      'createdAt': createdAt != null ? createdAt!.toIso8601String() : null,
    };
  }

  factory FoodItem.fromMap(Map<String, dynamic> map) {
    return FoodItem(
      id: map['id'] ?? '',
      name: map['name'] ?? '',
      calories: (map['calories'] as num?)?.toDouble() ?? 0.0,
      carbs: (map['carbs'] as num?)?.toDouble() ?? 0.0,
      protein: (map['protein'] as num?)?.toDouble() ?? 0.0,
      fat: (map['fat'] as num?)?.toDouble() ?? 0.0,
      servingSize: map['servingSize'] ?? '1 serving',
      quantity: (map['quantity'] as num?)?.toDouble() ?? 1.0,
      sodium: (map['sodium'] as num?)?.toDouble() ?? 0.0,
      potassium: (map['potassium'] as num?)?.toDouble() ?? 0.0,
      dietaryFibre: (map['dietaryFibre'] as num?)?.toDouble() ?? 0.0,
      sugars: (map['sugars'] as num?)?.toDouble() ?? 0.0,
      vitaminA: (map['vitaminA'] as num?)?.toDouble() ?? 0.0,
      vitaminC: (map['vitaminC'] as num?)?.toDouble() ?? 0.0,
      calcium: (map['calcium'] as num?)?.toDouble() ?? 0.0,
      iron: (map['iron'] as num?)?.toDouble() ?? 0.0,
      createdAt: map['createdAt'] != null
          ? DateTime.tryParse(map['createdAt'])
          : null,
    );
  }

  @override
  List<Object> get props => [
    id,
    name,
    calories,
    carbs,
    protein,
    fat,
    servingSize,
    quantity,
    sodium,
    potassium,
    dietaryFibre,
    sugars,
    vitaminA,
    vitaminC,
    calcium,
    iron,
  ];
}

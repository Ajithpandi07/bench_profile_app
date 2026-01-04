import 'package:equatable/equatable.dart';

class FoodItem extends Equatable {
  final String id;
  final String name;
  final double calories;
  final double carbs;
  final double protein;
  final double fat;
  final String servingSize;
  final int quantity; // e.g. 1 serving

  // Micro-nutrients
  final double sodium; // mg
  final double potassium; // g
  final double dietaryFibre; // g
  final double sugars; // g
  final double vitaminA; // %
  final double vitaminC; // %
  final double calcium; // %
  final double iron; // %

  const FoodItem({
    required this.id,
    required this.name,
    required this.calories,
    this.carbs = 0,
    this.protein = 0,
    this.fat = 0,
    this.servingSize = '1 serving',
    this.quantity = 1,
    this.sodium = 0,
    this.potassium = 0,
    this.dietaryFibre = 0,
    this.sugars = 0,
    this.vitaminA = 0,
    this.vitaminC = 0,
    this.calcium = 0,
    this.iron = 0,
  });

  FoodItem copyWith({
    String? id,
    String? name,
    double? calories,
    double? carbs,
    double? protein,
    double? fat,
    String? servingSize,
    int? quantity,
    double? sodium,
    double? potassium,
    double? dietaryFibre,
    double? sugars,
    double? vitaminA,
    double? vitaminC,
    double? calcium,
    double? iron,
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

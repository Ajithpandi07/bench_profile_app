import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../domain/entities/entities.dart';
import '../../../../core/utils/snackbar_utils.dart';
import '../bloc/bloc.dart';
import '../widgets/meal_list_shimmer.dart';
import '../widgets/primary_button.dart';
import 'add_food_page.dart';
import 'create_meal_page.dart';
import 'quick_log_page.dart';
import 'review_meal_page.dart';

class MealListingPage extends StatefulWidget {
  final String mealType;
  const MealListingPage({super.key, required this.mealType});

  @override
  State<MealListingPage> createState() => _MealListingPageState();
}

class _MealListingPageState extends State<MealListingPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  final Set<String> _selectedFoodIds = {};
  final Set<String> _selectedMealIds = {};

  // Store full objects to pass to review
  final List<FoodItem> _selectedFoods = [];
  final List<UserMeal> _selectedMealsList = [];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    context.read<MealBloc>().add(LoadUserLibrary());
  }

  void _toggleFoodSelection(FoodItem food) {
    setState(() {
      if (_selectedFoodIds.contains(food.id)) {
        _selectedFoodIds.remove(food.id);
        _selectedFoods.removeWhere((item) => item.id == food.id);
      } else {
        _selectedFoodIds.add(food.id);
        _selectedFoods.add(food);
      }
    });
  }

  void _toggleMealSelection(UserMeal meal) {
    setState(() {
      if (_selectedMealIds.contains(meal.id)) {
        _selectedMealIds.remove(meal.id);
        _selectedMealsList.removeWhere((item) => item.id == meal.id);
      } else {
        _selectedMealIds.add(meal.id);
        _selectedMealsList.add(meal);
      }
    });
  }

  void _onNext() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => BlocProvider.value(
          value: context.read<MealBloc>(),
          child: ReviewMealPage(
            mealType: widget.mealType,
            selectedFoods: _selectedFoods,
            selectedMeals: _selectedMealsList,
            allFoods: context.read<MealBloc>().state is UserLibraryLoaded
                ? (context.read<MealBloc>().state as UserLibraryLoaded).foods
                : [],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        leading: const BackButton(color: Colors.black),
        title: Text(
          widget.mealType,
          style: const TextStyle(
            color: Color(0xFFE93448),
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.info_outline, color: Color(0xFFE93448)),
            onPressed: () {},
          ),
        ],
      ),
      body: BlocListener<MealBloc, MealState>(
        listener: (context, state) {
          if (state is MealSaveSuccess) {
            // If we return from adding new item, maybe we select it?
            // For now just show snackbar
            // Note: If coming back from AddFoodPage, the Bloc should reload library?
            // AddFoodPage likely adds it.
          } else if (state is MealOperationFailure) {
            showModernSnackbar(context, state.message, isError: true);
          }
        },
        child: BlocBuilder<MealBloc, MealState>(
          builder: (context, state) {
            // Default empty lists
            List<FoodItem> userFoods = [];
            List<UserMeal> userMeals = [];

            if (state is MealLoading) {
              return const MealListShimmer();
            }

            if (state is UserLibraryLoaded) {
              userFoods = state.foods;
              userMeals = state.meals;
            }

            return Column(
              children: [
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 8.0),
                  child: Text(
                    'Choose how you want to log this meal.',
                    style: TextStyle(color: Colors.grey),
                  ),
                ),

                // Header Options
                // Headers
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      _buildHeaderAction(
                        Icons.room_service,
                        'Add\nNew Food',
                        () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => BlocProvider.value(
                                value: context.read<MealBloc>(),
                                child: const AddFoodPage(),
                              ),
                            ),
                          );
                        },
                      ),
                      _buildHeaderAction(
                        Icons.restaurant_menu,
                        'Create\nNew meal',
                        () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => BlocProvider.value(
                                value: context.read<MealBloc>(),
                                child: const CreateMealPage(),
                              ),
                            ),
                          );
                        },
                      ),
                      _buildHeaderAction(
                        Icons.local_fire_department,
                        'Quick\ncalories',
                        () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => BlocProvider.value(
                                value: context.read<MealBloc>(),
                                child: QuickLogPage(mealType: widget.mealType),
                              ),
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 24),

                // Toggle Tabs
                Container(
                  height: 37,
                  margin: const EdgeInsets.symmetric(horizontal: 24),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(18.5),
                  ),
                  child: TabBar(
                    controller: _tabController,
                    indicator: BoxDecoration(
                      color: const Color(0xFFE93448),
                      borderRadius: BorderRadius.circular(18.5),
                    ),
                    labelColor: Colors.white,
                    unselectedLabelColor: Colors.black54,
                    indicatorSize: TabBarIndicatorSize.tab,
                    dividerColor: Colors.transparent,
                    tabs: const [
                      Tab(text: 'My Food'),
                      Tab(text: 'My Meals'),
                    ],
                  ),
                ),

                const SizedBox(height: 16),

                // Search or List
                Expanded(
                  child: TabBarView(
                    controller: _tabController,
                    children: [
                      // My Food List
                      userFoods.isEmpty
                          ? const Center(child: Text('No custom foods added'))
                          : ListView.builder(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 24,
                                vertical: 10,
                              ),
                              itemCount: userFoods.length,
                              itemBuilder: (context, index) {
                                final food = userFoods[index];
                                final isSelected = _selectedFoodIds.contains(
                                  food.id,
                                );
                                return GestureDetector(
                                  onTap: () => _toggleFoodSelection(food),
                                  child: _buildListItem(
                                    food.name,
                                    '${food.calories.toStringAsFixed(0)} Kcal',
                                    isSelected,
                                  ),
                                );
                              },
                            ),
                      // My Meals List
                      userMeals.isEmpty
                          ? const Center(child: Text('No custom meals created'))
                          : ListView.builder(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 24,
                                vertical: 10,
                              ),
                              itemCount: userMeals.length,
                              itemBuilder: (context, index) {
                                final meal = userMeals[index];
                                final isSelected = _selectedMealIds.contains(
                                  meal.id,
                                );
                                return GestureDetector(
                                  onTap: () => _toggleMealSelection(meal),
                                  child: _buildListItem(
                                    meal.name,
                                    '${meal.totalCalories.toStringAsFixed(0)} Kcal',
                                    isSelected,
                                  ),
                                );
                              },
                            ),
                    ],
                  ),
                ),
              ],
            );
          },
        ),
      ),

      bottomNavigationBar:
          (_selectedFoodIds.isNotEmpty || _selectedMealIds.isNotEmpty)
          ? Container(
              padding: const EdgeInsets.all(24),
              decoration: const BoxDecoration(
                color: Colors.white,
                border: Border(top: BorderSide(color: Color(0xFFEEEEEE))),
              ),
              child: PrimaryButton(
                text: 'Next',
                onPressed: _onNext,
                width: double.infinity,
                height: 50,
                borderRadius: 12,
                fontSize: 16,
              ),
            )
          : null,
    );
  }

  Widget _buildHeaderAction(IconData icon, String label, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 100.56,
        height: 116,
        // Remove padding that might conflict with fixed height/centering
        // or keep vertical padding if content dictates.
        // Let's use Column's MainAxisAlignment to center content.
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: const Color(0xFFE93448), size: 26),
            const SizedBox(height: 4),
            Text(
              label,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
            ),
            const SizedBox(height: 4),
            const CircleAvatar(
              radius: 10,
              backgroundColor: Color(0xFFE93448),
              child: Icon(Icons.add, color: Colors.white, size: 14),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildListItem(String title, String subtitle, bool isSelected) {
    return Container(
      height: 50,
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: isSelected
            ? const Color(0xFFFFF0F1)
            : Colors.grey.shade50, // Light red tint if selected
        borderRadius: BorderRadius.circular(12),
        border: isSelected
            ? Border.all(color: const Color(0xFFE93448), width: 1.5)
            : Border.all(color: Colors.transparent),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Row(
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  subtitle,
                  style: const TextStyle(color: Colors.grey, fontSize: 13),
                ),
              ],
            ),
          ),
          if (isSelected)
            const Icon(Icons.check_circle, color: Color(0xFFE93448), size: 20)
          else
            const Icon(Icons.add_circle, color: Color(0xFFE93448), size: 20),
        ],
      ),
    );
  }
}

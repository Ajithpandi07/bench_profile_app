import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../domain/entities/entities.dart';
import '../../../../core/utils/snackbar_utils.dart';
import '../bloc/bloc.dart';
import 'add_food_page.dart';
import 'create_meal_page.dart';
import 'quick_log_page.dart';

class MealListingPage extends StatefulWidget {
  final String mealType;
  const MealListingPage({super.key, required this.mealType});

  @override
  State<MealListingPage> createState() => _MealListingPageState();
}

class _MealListingPageState extends State<MealListingPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    context.read<MealBloc>().add(LoadUserLibrary());
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
            showModernSnackbar(context, 'Added successfully!');
          } else if (state is MealOperationFailure) {
            showModernSnackbar(context, state.message, isError: true);
          }
        },
        child: BlocBuilder<MealBloc, MealState>(
          builder: (context, state) {
            // Default empty lists
            List<FoodItem> userFoods = [];
            List<UserMeal> userMeals = [];

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

                // Header Options (Add New Food, Create New Meal, Quick Calories)
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

                // Toggle Tabs (My Food / My Meals)
                Container(
                  height: 50,
                  margin: const EdgeInsets.symmetric(horizontal: 24),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(25),
                    // border: Border.all(color: Colors.grey.shade200),
                  ),
                  child: TabBar(
                    controller: _tabController,
                    indicator: BoxDecoration(
                      color: const Color(0xFFE93448),
                      borderRadius: BorderRadius.circular(25),
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
                              ),
                              itemCount: userFoods.length,
                              itemBuilder: (context, index) {
                                final food = userFoods[index];
                                return _buildListItem(
                                  food.name,
                                  '${food.calories.toStringAsFixed(0)} Kcal',
                                  false,
                                );
                              },
                            ),
                      // My Meals List
                      userMeals.isEmpty
                          ? const Center(child: Text('No custom meals created'))
                          : ListView.builder(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 24,
                              ),
                              itemCount: userMeals.length,
                              itemBuilder: (context, index) {
                                final meal = userMeals[index];
                                return _buildListItem(
                                  meal.name,
                                  '${meal.totalCalories.toStringAsFixed(0)} Kcal',
                                  false,
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
      // Floating Bottom Bar logic if items selected
    );
  }

  Widget _buildHeaderAction(IconData icon, String label, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 100,
        padding: const EdgeInsets.symmetric(vertical: 16),
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
          children: [
            Icon(
              icon,
              color: const Color(0xFFE93448),
              size: 28,
            ), // Actually needs thinner stroke icon
            const SizedBox(height: 8),
            Text(
              label,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
            ),
            const SizedBox(height: 8),
            const CircleAvatar(
              radius: 12,
              backgroundColor: Color(0xFFE93448),
              child: Icon(Icons.add, color: Colors.white, size: 16),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildListItem(String title, String subtitle, bool isSelected) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isSelected ? Colors.grey.shade100 : Colors.grey.shade50,
        borderRadius: BorderRadius.circular(12),
        border: isSelected
            ? Border.all(color: Colors.blue, width: 2)
            : Border.all(color: Colors.transparent), // Blue border in design
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 16,
                ),
              ),
              Text(
                subtitle,
                style: const TextStyle(color: Colors.grey, fontSize: 13),
              ),
            ],
          ),
          if (isSelected)
            const Icon(
              Icons.check_circle_outline,
              color: Colors.blue,
            ) // Or custom red check? Design uses red usually, but image shows Blue border + Red Check? Actually Red Check in Image 2.
          else
            const Icon(Icons.add_circle, color: Color(0xFFE93448)),
        ],
      ),
    );
  }
}

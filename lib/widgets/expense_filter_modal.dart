import 'package:expense_tracker_3_0/app_colors.dart';
import 'package:flutter/material.dart';

enum SortOption { newest, oldest, highestAmount, lowestAmount }

class FilterResult {
  final List<String> selectedCategories;
  final SortOption sortOption;

  FilterResult(this.selectedCategories, this.sortOption);
}

class ExpenseFilterModal extends StatefulWidget {
  final List<String> allCategories;
  final List<String> currentCategories;
  final SortOption currentSort;

  const ExpenseFilterModal({
    super.key,
    required this.allCategories,
    required this.currentCategories,
    required this.currentSort,
  });

  @override
  State<ExpenseFilterModal> createState() => _ExpenseFilterModalState();
}

class _ExpenseFilterModalState extends State<ExpenseFilterModal> {
  late List<String> _selectedCategories;
  late SortOption _selectedSort;

  @override
  void initState() {
    super.initState();
    // Create a copy to modify locally
    _selectedCategories = List.from(widget.currentCategories);
    _selectedSort = widget.currentSort;
  }

  void _toggleCategory(String category) {
    setState(() {
      if (_selectedCategories.contains(category)) {
        _selectedCategories.remove(category);
      } else {
        _selectedCategories.add(category);
      }
    });
  }

  void _apply() {
    Navigator.pop(context, FilterResult(_selectedCategories, _selectedSort));
  }

  void _reset() {
    setState(() {
      _selectedCategories.clear();
      _selectedSort = SortOption.newest;
    });
  }

  @override
  Widget build(BuildContext context) {

    return SafeArea(
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    "Filter & Sort",
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  TextButton(
                    onPressed: _reset,
                    child: const Text("Reset", style: TextStyle(color: AppColors.expense)),
                  ),
                ],
              ),
              const SizedBox(height: 20),

              // --- SORT SECTION ---
              const Text(
                "Sort By",
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 10,
                runSpacing: 10,
                children: [
                  _buildSortChip("Newest", SortOption.newest),
                  _buildSortChip("Oldest", SortOption.oldest),
                  _buildSortChip("Highest \$", SortOption.highestAmount),
                  _buildSortChip("Lowest \$", SortOption.lowestAmount),
                ],
              ),
              const SizedBox(height: 24),

              // --- CATEGORY SECTION ---
              const Text(
                "Categories",
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: widget.allCategories.map((category) {
                  final isSelected = _selectedCategories.contains(category);
                  return FilterChip(
                    label: Text(category),
                    selected: isSelected,
                    onSelected: (_) => _toggleCategory(category),
                    backgroundColor: AppColors.background,
                    selectedColor: AppColors.primary.withOpacity(0.15),
                    checkmarkColor: AppColors.primary,
                    labelStyle: TextStyle(
                      color: isSelected ? AppColors.primary : AppColors.textPrimary,
                      fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                      side: BorderSide(
                        color: isSelected ? AppColors.primary : Colors.transparent,
                        width: 1,
                      ),
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 30),

              // --- APPLY BUTTON ---
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _apply,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                    elevation: 0,
                  ),
                  child: const Text(
                    "Apply Filters",
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 20), 
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSortChip(String label, SortOption option) {
    final isSelected = _selectedSort == option;
    return ChoiceChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (selected) {
        if (selected) {
          setState(() => _selectedSort = option);
        }
      },
      backgroundColor: AppColors.background,
      selectedColor: AppColors.primary,
      labelStyle: TextStyle(
        color: isSelected ? Colors.white : AppColors.textPrimary,
        fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
      ),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      side: BorderSide.none, 
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
    );
  }
}
import 'package:expense_tracker_3_0/app_colors.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class TotalBudgetCard extends StatefulWidget {
  final double currentBudget;
  final Function(double) onBudgetChanged;

  const TotalBudgetCard({
    super.key,
    required this.currentBudget,
    required this.onBudgetChanged,
  });

  @override
  State<TotalBudgetCard> createState() => _TotalBudgetCardState();
}

class _TotalBudgetCardState extends State<TotalBudgetCard> {
  void _showEditBudgetModal() {
    String initialText = widget.currentBudget == 0 
        ? '' 
        : widget.currentBudget.toStringAsFixed(2);

    final TextEditingController controller = TextEditingController(text: initialText);

    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent, 
      builder: (BuildContext context) {
        return Padding(
          padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
          child: Container(
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(24.0),
                topRight: Radius.circular(24.0),
              ),
            ),
            padding: const EdgeInsets.all(30.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                const Text(
                  'Update Capital', 
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 20),
                TextField(
                  controller: controller,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  inputFormatters: [
                    FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d{0,2}')),
                  ],
                  style: const TextStyle(fontSize: 18),
                  decoration: InputDecoration(
                    labelText: 'Capital Amount',
                    prefixText: '₱ ',
                    labelStyle: const TextStyle(color: AppColors.textSecondary),
                    prefixStyle: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: const BorderSide(color: AppColors.primary, width: 2.0),
                    ),
                    filled: true,
                    fillColor: AppColors.background,
                  ),
                  autofocus: true,
                ),
                const SizedBox(height: 25),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () {
                      final newText = controller.text.trim();
                      final newAmount = double.tryParse(newText) ?? 0.0; 

                      Navigator.pop(context);
                      widget.onBudgetChanged(newAmount);
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      elevation: 0,
                    ),
                    child: const Text('Save Capital', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15), 
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Container(
            height: 36,
            width: 36,
            decoration: BoxDecoration(
              color: AppColors.secondary, 
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(
              Icons.savings,
              color: AppColors.primary,
              size: 22,
            ),
          ),
          const SizedBox(width: 12),

          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Initial Capital', 
                  style: TextStyle(
                    fontSize: 14,
                    color: AppColors.textSecondary,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '₱${widget.currentBudget.toStringAsFixed(2)}', 
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                ),
              ],
            ),
          ),

          // 🔥 RESTORED: Edit Button
          IconButton(
            icon: const Icon(Icons.edit),
            color: AppColors.primary,
            onPressed: _showEditBudgetModal,
            tooltip: 'Edit Capital',
          ),
        ],
      ),
    );
  }
}
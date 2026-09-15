import 'package:flutter/material.dart';

class IconoPago extends StatelessWidget {
  final ValueChanged<int> callbackfunction;
  final int selectedIndex;

  const IconoPago({
    super.key,
    required this.selectedIndex,
    required this.callbackfunction,
  });

  @override
  Widget build(BuildContext context) {
    final bool isSelected = selectedIndex == 1;
    const activeColor = Color(0xFF529471);
    const inactiveColor = Color(0xFF9E9E9E);

    return InkWell(
      onTap: () => callbackfunction(1),
      borderRadius: BorderRadius.circular(12),
      child: Container(
        height: 50,
        width: 50,
        margin: const EdgeInsets.symmetric(horizontal: 4),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                isSelected
                    ? Icons.credit_card_rounded
                    : Icons.credit_card_outlined,
                color: isSelected ? activeColor : inactiveColor,
                size: 22,
              ),
              const SizedBox(height: 2),
              Text(
                'Pagos',
                style: TextStyle(
                  color: isSelected ? activeColor : inactiveColor,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                  fontSize: 11,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

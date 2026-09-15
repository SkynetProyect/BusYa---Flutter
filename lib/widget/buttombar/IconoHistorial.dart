import 'package:flutter/material.dart';

class IconoHistorial extends StatelessWidget {
  final ValueChanged<int> callbackfunction;
  final int selectedIndex;

  const IconoHistorial({
    super.key,
    required this.selectedIndex,
    required this.callbackfunction,
  });

  @override
  Widget build(BuildContext context) {
    final bool isSelected = selectedIndex == 3;
    const activeColor = Color(0xFF529471);
    const inactiveColor = Color(0xFF9E9E9E);

    return InkWell(
      onTap: () => callbackfunction(3),
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
                isSelected ? Icons.history_rounded : Icons.history_outlined,
                color: isSelected ? activeColor : inactiveColor,
                size: 22,
              ),
              const SizedBox(height: 2),
              Text(
                'Historial',
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

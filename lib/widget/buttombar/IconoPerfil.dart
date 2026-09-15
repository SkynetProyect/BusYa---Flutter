import 'package:flutter/material.dart';

class IconoPerfil extends StatelessWidget {
  final ValueChanged<int> callbackfunction;
  final int selectedIndex;

  const IconoPerfil({
    super.key,
    required this.selectedIndex,
    required this.callbackfunction,
  });

  @override
  Widget build(BuildContext context) {
    final bool isSelected = selectedIndex == 4;
    const activeColor = Color(0xFF529471);
    const inactiveColor = Color(0xFF9E9E9E);

    return InkWell(
      onTap: () => callbackfunction(4),
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
                isSelected ? Icons.person_rounded : Icons.person_outlined,
                color: isSelected ? activeColor : inactiveColor,
                size: 22,
              ),
              const SizedBox(height: 2),
              Text(
                'Perfil',
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

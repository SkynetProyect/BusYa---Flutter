import 'package:flutter/material.dart';

class IconoHistorial extends StatelessWidget {
  final ValueChanged<int> callbackfunction;
  final int selectedIndex;

  const IconoHistorial({
    required this.selectedIndex,
    required this.callbackfunction,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) {
        callbackfunction(3);
      },
      child: Container(
        height: 50,
        width: 40,
        margin: EdgeInsets.symmetric(horizontal: 4),
        child: Center(
          child: Column(
            children: [
              Icon(
                Icons.history,
                color: selectedIndex == 3 ? Colors.white : Colors.black,
              ),
              Text(
                'Historial',
                style: TextStyle(
                  color: selectedIndex == 3 ? Colors.white : Colors.black,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

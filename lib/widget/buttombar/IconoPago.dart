import 'package:flutter/material.dart';

class IconoPago extends StatelessWidget {
  final ValueChanged<int> callbackfunction;
  final int selectedIndex;

  const IconoPago({
    required this.selectedIndex,
    required this.callbackfunction,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) {
        callbackfunction(1);
      },
      child: Container(
        height: 50,
        width: 40,
        margin: EdgeInsets.symmetric(horizontal: 4),
        child: Center(
          child: Column(
            children: [
              Icon(
                Icons.credit_card,
                color: selectedIndex == 1 ? Colors.white : Colors.black,
              ),
              Text(
                'Pagos',
                style: TextStyle(
                  color: selectedIndex == 1 ? Colors.white : Colors.black,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

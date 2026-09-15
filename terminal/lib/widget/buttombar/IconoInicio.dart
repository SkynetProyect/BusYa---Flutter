import 'package:flutter/material.dart';

class IconoInicio extends StatelessWidget {
  final ValueChanged<int> callbackfunction;
  final int selectedIndex;

  const IconoInicio({
    required this.selectedIndex,
    required this.callbackfunction,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) {
        callbackfunction(0);
      },
      child: Container(
        height: 50,
        width: 40,
        margin: EdgeInsets.only(left: 20, right: 20),
        child: Center(
          child: Column(
            children: [
              Icon(
                Icons.map_outlined,
                color: selectedIndex == 0 ? Colors.white : Colors.black,
              ),
              Text(
                'Inicio',
                style: TextStyle(
                  color: selectedIndex == 0 ? Colors.white : Colors.black,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

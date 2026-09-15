import 'package:flutter/material.dart';

class IconoPerfil extends StatelessWidget {
  final ValueChanged<int> callbackfunction;
  final int selectedIndex;

  const IconoPerfil({
    required this.selectedIndex,
    required this.callbackfunction,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) {
        callbackfunction(4);
      },
      child: Container(
        height: 50,
        width: 40,
        margin: EdgeInsets.only(left: 20, right: 20),
        child: Center(
          child: Column(
            children: [
              Icon(
                Icons.person_2_outlined,
                color: selectedIndex == 4 ? Colors.white : Colors.black,
              ),
              Text(
                'Perfil',
                style: TextStyle(
                  color: selectedIndex == 4 ? Colors.white : Colors.black,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

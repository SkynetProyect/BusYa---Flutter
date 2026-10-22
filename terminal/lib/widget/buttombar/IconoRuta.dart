import 'package:flutter/material.dart';
import 'package:flutter_application_1/core/app_colors.dart';

class IconoRuta extends StatelessWidget {
  final ValueChanged<int> callbackfunction;
  final int selectedIndex;

  const IconoRuta({
    super.key,
    required this.selectedIndex,
    required this.callbackfunction,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) {
        callbackfunction(2);
      },
      child: Container(
        height: 50,
        width: 40,
        margin: EdgeInsets.only(left: 20, right: 20),
        child: Center(
          child: Column(
            children: [
              Icon(
                Icons.route_outlined,
                color: selectedIndex == 2
                    ? AppColors.surfaceWhite
                    : AppColors.textBlack,
              ),
              Text(
                'Ruta',
                style: TextStyle(
                  color: selectedIndex == 2
                      ? AppColors.surfaceWhite
                      : AppColors.textBlack,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

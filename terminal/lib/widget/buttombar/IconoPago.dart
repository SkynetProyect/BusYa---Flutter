import 'package:flutter/material.dart';
import 'package:flutter_application_1/core/app_colors.dart';

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
    return GestureDetector(
      onTapDown: (_) {
        callbackfunction(1);
      },
      child: Container(
        height: 50,
        width: 40,
        margin: EdgeInsets.only(left: 20, right: 20),
        child: Center(
          child: Column(
            children: [
              Icon(
                Icons.credit_card,
                color: selectedIndex == 1
                    ? AppColors.surfaceWhite
                    : AppColors.textBlack,
              ),
              Text(
                'Pagos',
                style: TextStyle(
                  color: selectedIndex == 1
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

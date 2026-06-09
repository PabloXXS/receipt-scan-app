import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ticket_app/core/theme/app_colors.dart';

void main() {
  test('seed — emerald #2E7D5B', () {
    expect(AppColors.seed, const Color(0xFF2E7D5B));
  });

  test('семантические цвета заданы для light и dark', () {
    expect(AppColors.priceUpLight, isNot(AppColors.priceDownLight));
    expect(AppColors.priceUpDark, isNot(AppColors.priceDownDark));
    expect(AppColors.successLight, isA<Color>());
    expect(AppColors.warningDark, isA<Color>());
  });
}

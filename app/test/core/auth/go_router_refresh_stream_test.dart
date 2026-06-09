import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:ticket_app/core/auth/auth_providers.dart';

void main() {
  test('GoRouterRefreshStream уведомляет при событии стрима', () async {
    final controller = StreamController<int>();
    addTearDown(controller.close);
    final refresh = GoRouterRefreshStream(controller.stream);
    addTearDown(refresh.dispose);

    var notifications = 0;
    refresh.addListener(() => notifications++);

    controller.add(1);
    await Future<void>.delayed(Duration.zero);

    expect(notifications, greaterThanOrEqualTo(1));
  });
}

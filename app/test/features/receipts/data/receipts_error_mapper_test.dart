import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:ticket_app/core/error/failure.dart';
import 'package:ticket_app/features/receipts/data/receipts_error_mapper.dart';

void main() {
  test('SocketException → ReceiptsNetworkFailure', () {
    expect(mapReceiptsException(const SocketException('x')),
        isA<ReceiptsNetworkFailure>());
  });

  test('PostgrestException → ReceiptsLoadFailure', () {
    expect(
      mapReceiptsException(const PostgrestException(message: 'boom')),
      isA<ReceiptsLoadFailure>(),
    );
  });

  test('готовый ReceiptsFailure возвращается как есть', () {
    const f = ReceiptsDeleteFailure();
    expect(mapReceiptsException(f), same(f));
  });

  test('прочее → UnknownReceiptsFailure', () {
    expect(mapReceiptsException(Exception('x')), isA<UnknownReceiptsFailure>());
  });
}

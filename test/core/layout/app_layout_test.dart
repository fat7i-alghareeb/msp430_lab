import 'package:flutter_test/flutter_test.dart';
import 'package:msp430_lab/core/layout/app_breakpoints.dart';
import 'package:msp430_lab/core/layout/app_layout.dart';

void main() {
  test('window width picks the size class', () {
    expect(AppBreakpoints.medium, 600);
    expect(AppLayout.columnsFor(400), 1);
    expect(AppLayout.columnsFor(1000), greaterThanOrEqualTo(2));
  });
}

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:presentum/src/state/slot_state.dart';
import 'package:presentum/src/widgets/popup_host.dart';

import '../fake_payload.dart';

typedef _SlotState = PresentumSlotState<FakeItem, FakeSurface, FakeVariant>;

void main() {
  group('PresentumPopupHost', () {
    testWidgets('onShown runs before present', (tester) async {
      final item = createFakeItem(
        'popup',
        FakeSurface.modal,
        FakeVariant.variantA,
      );
      final order = <String>[];

      await tester.pumpWidget(
        MaterialApp(
          home: PresentumPopupHost<FakeItem, FakeSurface, FakeVariant>(
            slots: const _SlotState.empty().withActive(FakeSurface.modal, item),
            surface: FakeSurface.modal,
            onShown: (shown) async => order.add('shown'),
            present: (shown) async {
              order.add('present');
              return PopupPresentResult.userDismissed;
            },
            child: const SizedBox(),
          ),
        ),
      );

      await tester.pump();
      await tester.pump();

      expect(order, ['shown', 'present']);
    });

    testWidgets('systemDismissed calls onMarkDismissed', (tester) async {
      final item = createFakeItem(
        'popup',
        FakeSurface.modal,
        FakeVariant.variantA,
      );
      String? dismissedId;

      await tester.pumpWidget(
        MaterialApp(
          home: PresentumPopupHost<FakeItem, FakeSurface, FakeVariant>(
            slots: const _SlotState.empty().withActive(FakeSurface.modal, item),
            surface: FakeSurface.modal,
            present: (_) async => PopupPresentResult.systemDismissed,
            onMarkDismissed: (dismissed) async =>
                dismissedId = dismissed.payload.id,
            child: const SizedBox(),
          ),
        ),
      );

      await tester.pump();
      await tester.pump();

      expect(dismissedId, 'popup');
    });
  });
}

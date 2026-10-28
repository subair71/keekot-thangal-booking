import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/bootstrap/providers.dart';

/// In-memory UI state only. The server remains authoritative for holds/booking.
typedef VisitSelection = ({
  String? day,
  String? slotId,
  int visitors,
  String period,
});

class VisitSelectionController extends Notifier<VisitSelection> {
  @override
  VisitSelection build() =>
      (day: null, slotId: null, visitors: 1, period: 'All times');
  void save(VisitSelection value) => state = value;
  void clear() => state = build();
}

final visitSelectionProvider =
    NotifierProvider<VisitSelectionController, VisitSelection>(
      VisitSelectionController.new,
    );

typedef VisitorForm = ({String name, String address, String phone});

class VisitorFormController extends Notifier<VisitorForm> {
  @override
  VisitorForm build() {
    // Personal details never survive an account change or sign-out.
    ref.watch(authProvider.select((value) => value.asData?.value?.id));
    return (name: '', address: '', phone: '');
  }

  void save(VisitorForm value) => state = value;
  void clear() => state = (name: '', address: '', phone: '');
}

final visitorFormProvider =
    NotifierProvider<VisitorFormController, VisitorForm>(
      VisitorFormController.new,
    );

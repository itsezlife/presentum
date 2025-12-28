import 'package:flutter/foundation.dart';
import 'package:shorebird_code_push/shorebird_code_push.dart';

class ShorebirdUpdatesStore extends ChangeNotifier {
  ShorebirdUpdatesStore({required this.updater});

  final ShorebirdUpdater updater;

  UpdateStatus? _status;
  UpdateStatus? get status => _status;

  Future<UpdateStatus> checkForUpdate() async {
    final status = await updater.checkForUpdate();
    if (status == _status) return status;
    _status = status;
    notifyListeners();
    return status;
  }

  Future<void> update() async {
    await updater.update();
    final status = await updater.checkForUpdate();
    _status = status;
    notifyListeners();
  }
}

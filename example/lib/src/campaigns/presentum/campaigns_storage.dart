import 'package:example/src/campaigns/camapigns.dart';
import 'package:example/src/common/presentum/persistent_presentum_storage.dart';

class CampaignPersistentStorage
    extends PersistentPresentumStorage<CampaignSurface, CampaignVariant> {
  CampaignPersistentStorage({required super.prefs});
}

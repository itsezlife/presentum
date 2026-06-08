import 'package:example/src/feature/presentum/payload.dart';
import 'package:shared/shared.dart';

/// Local feature payloads bundled with the example app.
const featureLocalPayloads = <String, FeaturePayload>{
  FeatureId.newYearTheme: FeaturePayload(
    id: FeatureId.newYearTheme,
    featureKey: FeatureId.newYearTheme,
    priority: 50,
    metadata: {
      'any_of': [
        {
          'time_range': {
            'start': '2025-12-01T18:00:00Z',
            'end': '2026-01-03T23:59:59Z',
          },
        },
        {'is_active': true},
      ],
    },
    options: [
      FeatureOption(
        surface: AppSurface.background,
        variant: AppVariant.snow,
        stage: 0,
        isDismissible: false,
        alwaysOnIfEligible: true,
      ),
    ],
  ),
  FeatureId.newYearBanner: FeaturePayload(
    id: FeatureId.newYearBanner,
    featureKey: FeatureId.newYearBanner,
    dependsOnFeatureKey: FeatureId.newYearBanner,
    priority: 50,
    metadata: {
      'year': '2026',
      'any_of': [
        {
          'time_range': {
            'start': '2025-12-31T18:00:00Z',
            'end': '2026-01-03T23:59:59Z',
          },
        },
        {'is_active': true},
      ],
    },
    options: [
      FeatureOption(
        surface: AppSurface.popup,
        variant: AppVariant.fullscreenDialog,
        isDismissible: true,
        stage: 0,
        maxImpressions: 1,
        alwaysOnIfEligible: false,
      ),
      FeatureOption(
        surface: AppSurface.homeHeader,
        variant: AppVariant.banner,
        isDismissible: true,
        alwaysOnIfEligible: true,
      ),
    ],
  ),
  FeatureId.catalogCategoriesSection: FeaturePayload(
    id: FeatureId.catalogCategoriesSection,
    featureKey: FeatureId.catalogCategoriesSection,
    dependsOnFeatureKey: FeatureId.catalogCategoriesSection,
    priority: 200,
    metadata: {},
    options: [
      FeatureOption(
        surface: AppSurface.catalogView,
        variant: AppVariant.catalogCategoriesSection,
        stage: 200,
        isDismissible: false,
        alwaysOnIfEligible: true,
      ),
    ],
  ),
  FeatureId.catalogRecentlyViewedProductsSection: FeaturePayload(
    id: FeatureId.catalogRecentlyViewedProductsSection,
    featureKey: FeatureId.catalogRecentlyViewedProductsSection,
    dependsOnFeatureKey: FeatureId.catalogRecentlyViewedProductsSection,
    priority: 400,
    metadata: {},
    options: [
      FeatureOption(
        surface: AppSurface.catalogView,
        variant: AppVariant.catalogRecentlyViewedProductsSection,
        stage: 300,
        isDismissible: false,
        alwaysOnIfEligible: true,
      ),
    ],
  ),
};

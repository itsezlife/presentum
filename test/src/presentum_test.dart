// Not required for test files

import 'package:flutter_test/flutter_test.dart';

import 'integration/eligibility/recurring_time_pattern_test.dart'
    as recurring_time_pattern_integration_test;
import 'unit/eligibility/metadata_extraction_test.dart'
    as metadata_extraction_test;
import 'unit/eligibility/recurring_time_pattern_test.dart'
    as recurring_time_pattern_test;
import 'unit/transitions_test.dart' as transitions_test;

void main() {
  group('unit', () {
    transitions_test.main();
    recurring_time_pattern_test.main();
    metadata_extraction_test.main();
  });
  group('integration', recurring_time_pattern_integration_test.main);
}

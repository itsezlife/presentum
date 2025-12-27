import 'package:flutter/foundation.dart';
import 'package:presentum/presentum.dart';
import 'package:shorebird_code_push/shorebird_code_push.dart';

/// Eligibility condition that checks if update status matches required status
@immutable
final class UpdateStatusEligibility extends Eligibility {
  const UpdateStatusEligibility({required this.requiredStatus});

  final UpdateStatus requiredStatus;
}

/// Rule that evaluates UpdateStatusEligibility
final class UpdateStatusRule
    implements EligibilityRule<UpdateStatusEligibility> {
  const UpdateStatusRule();

  @override
  bool supports(Eligibility eligibility) =>
      eligibility is UpdateStatusEligibility;

  @override
  Future<bool> evaluate(
    UpdateStatusEligibility eligibility,
    Map<String, dynamic> context,
  ) async {
    final currentStatus = context['update_status'] as UpdateStatus?;
    if (currentStatus == null) return false;

    return currentStatus == eligibility.requiredStatus;
  }
}

/// Extractor that pulls UpdateStatusEligibility from payload metadata
final class UpdateStatusExtractor<T extends HasMetadata>
    extends MetadataExtractor<T> {
  const UpdateStatusExtractor({this.metadataKey = 'required_update_status'});

  final String metadataKey;

  @override
  bool supports(T subject) => subject.metadata.containsKey(metadataKey);

  @override
  List<Eligibility> extract(T subject) {
    final statusStr = requireString(subject.metadata[metadataKey], metadataKey);

    // Parse the status string to UpdateStatus enum
    final status = switch (statusStr) {
      'restartRequired' => UpdateStatus.restartRequired,
      'outdated' => UpdateStatus.outdated,
      'upToDate' => UpdateStatus.upToDate,
      'unavailable' => UpdateStatus.unavailable,
      _ => null,
    };

    if (status == null) {
      Error.throwWithStackTrace(
        MalformedMetadataException(
          'Invalid update status in "$metadataKey"',
          'received: $statusStr',
        ),
        StackTrace.current,
      );
    }

    return [UpdateStatusEligibility(requiredStatus: status)];
  }
}

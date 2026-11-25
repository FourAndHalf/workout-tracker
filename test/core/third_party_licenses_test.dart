import 'dart:io';

import 'package:fitness_tracker/core/legal/third_party_licenses.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test(
    'the anatomy licence is registered once with the full MIT text',
    () async {
      registerThirdPartyLicenses();
      registerThirdPartyLicenses();
      final entries = await LicenseRegistry.licenses
          .where((e) => e.packages.contains(anatomyLicensePackage))
          .toList();
      expect(entries, hasLength(1));
      final text = entries.single.paragraphs.map((p) => p.text).join('\n');
      expect(text, contains('MIT License'));
      expect(text, contains('ELABBASSI Hicham'));
    },
  );

  test('the bundled licence matches the copy in third_party/', () {
    final copy = File('third_party/react-native-body-highlighter/LICENSE')
        .readAsStringSync();
    expect(anatomyLicenseText.trim(), copy.trim());
  });
}

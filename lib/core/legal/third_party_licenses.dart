import 'package:flutter/foundation.dart';

/// Package name shown on the licences page for the body figure's artwork.
const anatomyLicensePackage = 'react-native-body-highlighter (anatomy paths)';

/// Credit line shown next to the Explore body figure.
const anatomyCredit =
    'Body figure: react-native-body-highlighter, MIT © 2022 ELABBASSI Hicham';

/// MIT licence of the anatomy SVG paths in `anatomy_paths.g.dart`; a copy
/// lives in `third_party/react-native-body-highlighter/LICENSE`.
const anatomyLicenseText = r'''
MIT License

Copyright (c) 2022 ELABBASSI Hicham

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.''';

bool _registered = false;

/// Adds licences for bundled third-party artwork to Flutter's
/// [LicenseRegistry] so they appear on the app's licences page.
/// Safe to call more than once.
void registerThirdPartyLicenses() {
  if (_registered) return;
  _registered = true;
  LicenseRegistry.addLicense(
    () => Stream.value(
      const LicenseEntryWithLineBreaks([
        anatomyLicensePackage,
      ], anatomyLicenseText),
    ),
  );
}

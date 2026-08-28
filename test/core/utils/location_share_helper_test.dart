import 'package:flutter_test/flutter_test.dart';

// LocationShareHelper's three methods (shareCurrentLocation, launchDialer,
// launchEmail) each go straight from inputs to a plugin call with no
// extracted pure logic and no injectable seam:
//   - shareCurrentLocation constructs `LocationService()` internally (not
//     injected) and its maps-link/message string is built inline in the same
//     expression that's passed to `Share.share(...)` — there's no standalone
//     function to call and assert on without also invoking the real
//     LocationService/share_plus plugin.
//   - launchDialer/launchEmail build a `Uri` inline and pass it directly to
//     url_launcher's `launchUrl`, again with no seam to intercept before the
//     plugin call.
//
// Per the task's testability contract, plugin statics are not to be invoked
// from a unit test, and none of the three methods expose a pure branch to
// exercise in isolation. Closing this gap needs the same optional
// constructor-injection pattern used in LocationService/PlacesService (e.g.
// injecting a LocationService instance, a `ShareFn`, and a `LaunchUrlFn`)
// added to LocationShareHelper in a future change; this file documents the
// gap rather than skip-list a suite of no-op tests.
void main() {
  test(
    'LocationShareHelper has no seam for unit testing without invoking share_plus/url_launcher/LocationService plugin code',
    () {},
    skip:
        'shareCurrentLocation/launchDialer/launchEmail call plugin statics '
        '(Share.share, launchUrl) and construct LocationService() inline with '
        'no injectable seam — needs a testability refactor (out of scope for '
        'this pass) before it can be unit tested.',
  );
}

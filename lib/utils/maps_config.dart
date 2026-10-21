/// Google Maps availability.
///
/// google_maps_flutter needs an API key per platform, otherwise the native SDK
/// crashes (Android) or shows a blank map (web/iOS):
///   * Android: `<meta-data android:name="com.google.android.geo.API_KEY"
///     android:value="YOUR_KEY"/>` inside `<application>` in
///     android/app/src/main/AndroidManifest.xml
///   * iOS: `GMSServices.provideAPIKey("YOUR_KEY")` in AppDelegate
///   * Web: the Maps JavaScript API `<script>` tag in web/index.html
///
/// No key is configured in this project yet, so map screens use Metromate's
/// built-in schematic map. After adding the key, build with
/// `--dart-define=GOOGLE_MAPS_ENABLED=true` to switch to Google Maps.
class MapsConfig {
  static const bool googleMapsEnabled = bool.fromEnvironment('GOOGLE_MAPS_ENABLED');
}

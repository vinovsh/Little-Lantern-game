"""Install the pinned official Godot Android source template and native ads bridge.

Run from the repo root. The default config disables all ad SDK network initialization.
Pass --ads-config with a reviewed config to enable test or production placements.
"""
import argparse, json, shutil, zipfile
from pathlib import Path
from xml.sax.saxutils import escape

root = Path(__file__).resolve().parents[1]
parser = argparse.ArgumentParser()
parser.add_argument('--template', type=Path, required=True)
parser.add_argument('--ads-config', type=Path, default=root/'native/android/ads-config.example.json')
args = parser.parse_args()
build = root/'android/build'
build.mkdir(parents=True, exist_ok=True)
(root/'android/.gdignore').write_text('')
(build/'.gdignore').write_text('')
# Remove Godot importer metadata left by an earlier unignored generated directory.
for metadata in build.rglob('*.import'):
    metadata.unlink()
with zipfile.ZipFile(args.template) as archive:
    # Official export template is a trusted build dependency. Reject traversal paths.
    for item in archive.infolist():
        dest = (build/item.filename).resolve()
        if not dest.is_relative_to(build.resolve()):
            raise RuntimeError('Invalid template path')
    archive.extractall(build)
config = json.loads(args.ads_config.read_text())
source = build/'src/com/rendermind/littlelantern/LanternAds.java'
source.parent.mkdir(parents=True, exist_ok=True)
shutil.copyfile(root/'native/android/LanternAds.java', source)
gradle = build/'build.gradle'
with gradle.open('a') as file:
    file.write('''
// Little Lantern native advertising bridge. Exact versions are pinned.
dependencies {
    implementation 'com.google.android.gms:play-services-ads:25.5.0'
    implementation 'com.google.android.ump:user-messaging-platform:4.0.0'
}
''')
manifest = build/'AndroidManifest.xml'
text = manifest.read_text()
entries = {
    'org.godotengine.plugin.v2.LanternAds':'com.rendermind.littlelantern.LanternAds',
    'com.google.android.gms.ads.APPLICATION_ID':config['app_id'],
    'littlelantern.ads_enabled':str(bool(config.get('enabled', False))).lower(),
    'littlelantern.rewarded_id':config['rewarded_id'],
    'littlelantern.interstitial_id':config['interstitial_id'],
}
tags = '\n'.join(f'        <meta-data android:name="{key}" android:value="{escape(value)}" />' for key,value in entries.items())
text = text.replace('    </application>',tags+'\n    </application>')
if config.get('enabled', False):
    text = text.replace('    <application','    <uses-permission android:name="android.permission.INTERNET" />\n    <uses-permission android:name="android.permission.ACCESS_NETWORK_STATE" />\n    <application',1)
manifest.write_text(text)
(root/'android/.build_version').write_text('4.5.1.stable\n')
(build/'gradlew').chmod(0o755)
wrapper = build/'gradle/wrapper/gradle-wrapper.properties'
wrapper.write_text(wrapper.read_text().replace('gradle-8.11.1-bin.zip', 'gradle-8.13-bin.zip'))
print(f'Prepared {build}; ads enabled: {bool(config.get("enabled",False))}')

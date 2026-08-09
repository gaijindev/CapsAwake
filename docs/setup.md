# Local setup

Requirements:

- macOS 14 or newer
- Xcode 16 or newer (Xcode 26 is used in CI)
- `xcodegen` for regenerating the checked-in project

Run the pure core tests with:

```sh
swift test
```

Build and test the native app with:

```sh
xcodegen generate
xcodebuild -project CapsAwake.xcodeproj -scheme CapsAwake \
  -destination 'platform=macOS' test CODE_SIGNING_ALLOWED=NO
```

Open `CapsAwake.xcodeproj` in Xcode when you want to run the menu-bar app. The first launch shows a compact explanation and keeps Launch at Login opt-in.

Use `Scripts/check-format.sh` before opening a pull request. The app is sandboxed and does not need Accessibility or Input Monitoring permission.

## Installed smoke test

To install the current local build for hands-on testing:

```sh
CONFIGURATION=Debug DERIVED_DATA_PATH="$PWD/.build/xcode" ./Scripts/build-app.sh
ditto --rsrc .build/xcode/Build/Products/Debug/CapsAwake.app /Applications/CapsAwake.app
open /Applications/CapsAwake.app
```

Toggle Caps Lock and open the menu-bar popover. With Caps Lock on, the active
reason should say `Caps Lock`, and this command should show
`CapsAwake keeps the Mac awake`:

```sh
pmset -g assertions
```

Toggle Caps Lock off and confirm the CapsAwake assertion disappears. Then test
a custom timer, Presentation, Allow Sleep Now, Resume Automation, one weekly
schedule, and one app rule. The first-run explanation and notification toggles
are opt-in; no Accessibility or Input Monitoring prompt should appear.

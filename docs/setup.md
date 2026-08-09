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

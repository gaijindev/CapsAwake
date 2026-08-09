cask "capsawake" do
  version "1.0.0"
  sha256 :no_check

  url "https://github.com/gaijindev/CapsAwake/releases/download/v#{version}/CapsAwake.zip"
  name "CapsAwake"
  desc "Keep your Mac awake while Caps Lock is on"
  homepage "https://github.com/gaijindev/CapsAwake"

  app "CapsAwake.app"

  zap trash: [
    "~/Library/Application Support/CapsAwake",
    "~/Library/Preferences/com.gaijindev.CapsAwake.plist"
  ]
end

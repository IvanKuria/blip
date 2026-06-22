cask "blip" do
  version "0.1.0"

  # TODO: Pin the real checksum before publishing. Get it from the build script
  # output (`shasum -a 256 build/Blip-<version>.dmg`) and replace :no_check:
  #   sha256 "<paste-the-64-char-hex-digest-here>"
  sha256 :no_check

  url "https://github.com/IvanKuria/blip/releases/download/v#{version}/Blip-#{version}.dmg"
  name "Blip"
  desc "macOS app by Ivan Kuria"
  homepage "https://github.com/IvanKuria/blip"

  app "Blip.app"

  zap trash: [
    "~/Library/Preferences/com.ivankuria.blip.plist",
    "~/Library/Caches/com.ivankuria.blip",
    "~/Library/Application Support/Blip",
    "~/Library/Saved Application State/com.ivankuria.blip.savedState",
    "~/Library/HTTPStorages/com.ivankuria.blip",
  ]
end

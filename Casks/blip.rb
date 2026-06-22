cask "blip" do
  version "0.1.0"

  sha256 "6c7b754c4f942d9e2fbf06234f3732ce987de9968bd22fb6f0ffd1c3fb35a12b"

  url "https://github.com/IvanKuria/blip/releases/download/v#{version}/Blip-#{version}.dmg"
  name "Blip"
  desc "Confirms every copy in your notch - and shows what you grabbed"
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

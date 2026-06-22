cask "blip" do
  version "0.1.0"

  sha256 "c71a8617e0a8181d2ade8a345fa2ada691575b9e72b059e9ae9f8806a85f283b"

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

cask "tailbar" do
  version :latest
  sha256 :no_check

  url "https://github.com/junghoonkye/TailBar/releases/latest/download/TailBar.zip"
  name "TailBar"
  desc "Tailscale management menu bar app for macOS"
  homepage "https://github.com/junghoonkye/TailBar"

  depends_on macos: ">= :sonoma"

  binary "TailBar"

  zap trash: [
    "~/Library/Preferences/com.tailbar.app.plist",
  ]
end

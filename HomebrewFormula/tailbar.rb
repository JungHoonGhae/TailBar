class Tailbar < Formula
  desc "Tailscale management menu bar app for macOS"
  homepage "https://github.com/JungHoonGhae/TailBar"
  url "https://github.com/JungHoonGhae/TailBar/releases/download/v0.1.0/TailBar-v0.1.0.zip"
  sha256 "8160d1dee5218d8d7c9190bf4bb1fb424b1cd93f239446aa6a4ae60fe64b6250"
  license "MIT"

  depends_on :macos

  def install
    bin.install "TailBar" => "tailbar"
  end

  def caveats
    <<~EOS
      TailBar runs as a menu bar app (no Dock icon).
      Start it with:
        tailbar
      Requires Tailscale to be installed and running.
    EOS
  end

  test do
    assert_predicate bin/"tailbar", :exist?
  end
end

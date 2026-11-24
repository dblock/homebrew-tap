# Generated from the latest dblock/fue-rs release by bin/update-formula; do not edit.
class Fue < Formula
  desc "Find e-mail addresses of GitHub users and repository contributors"
  homepage "https://github.com/dblock/fue-rs"
  license "MIT"

  on_macos do
    on_arm do
      url "https://github.com/dblock/fue-rs/releases/download/v0.1.2/fue-0.1.2-aarch64-apple-darwin.tar.gz"
      sha256 "efdc128fd6253388b2365e3dc4cbff01b93d0a210a7a6fd6a64b11946a9297f0"
    end
    on_intel do
      url "https://github.com/dblock/fue-rs/releases/download/v0.1.2/fue-0.1.2-x86_64-apple-darwin.tar.gz"
      sha256 "3d6b73625681741dec27088c1c6ddd103f5558ffb0f931de28a1f299378ae660"
    end
  end

  on_linux do
    on_arm do
      url "https://github.com/dblock/fue-rs/releases/download/v0.1.2/fue-0.1.2-aarch64-unknown-linux-musl.tar.gz"
      sha256 "957706ac8a1120785a24896b24953de7c2a39e17c4b86797eea0d57b64af8378"
    end
    on_intel do
      url "https://github.com/dblock/fue-rs/releases/download/v0.1.2/fue-0.1.2-x86_64-unknown-linux-musl.tar.gz"
      sha256 "0c337468be5744fc11119de5389499b004c2b362e42a4367f22551783baa3fda"
    end
  end

  def install
    bin.install "fue"
  end

  test do
    assert_equal "fue #{version}", shell_output("#{bin}/fue --version").strip
  end
end

# Generated from the latest dblock/fue-rs release by bin/update-formula; do not edit.
class Fue < Formula
  desc "Find e-mail addresses of GitHub users and repository contributors"
  homepage "https://github.com/dblock/fue-rs"
  license "MIT"

  on_macos do
    on_arm do
      url "https://github.com/dblock/fue-rs/releases/download/v0.1.1/fue-0.1.1-aarch64-apple-darwin.tar.gz"
      sha256 "74de160c536de6fa8c3f8b3017419471f502aa240217e2db8ec8560819874e9f"
    end
    on_intel do
      url "https://github.com/dblock/fue-rs/releases/download/v0.1.1/fue-0.1.1-x86_64-apple-darwin.tar.gz"
      sha256 "a9b9fe6531881b45d828928bc61bccae03b1f6e546ab7ea9480ea0b9dd543bf0"
    end
  end

  on_linux do
    on_arm do
      url "https://github.com/dblock/fue-rs/releases/download/v0.1.1/fue-0.1.1-aarch64-unknown-linux-musl.tar.gz"
      sha256 "a52a0295bfa04618ac53db6b6fd35296a2bb599a586e2f93467255c4d99c744d"
    end
    on_intel do
      url "https://github.com/dblock/fue-rs/releases/download/v0.1.1/fue-0.1.1-x86_64-unknown-linux-musl.tar.gz"
      sha256 "2b857e126c02eb1bf6ba9a0feeeb2fd4676cb31b79fc3520ac14b7ec19db688f"
    end
  end

  def install
    bin.install "fue"
  end

  test do
    assert_equal "fue #{version}", shell_output("#{bin}/fue --version").strip
  end
end

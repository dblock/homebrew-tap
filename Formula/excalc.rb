# Generated from the latest dblock/excalc-rs release by bin/update-formula; do not edit.
class Excalc < Formula
  desc "Expression calculator CLI tool and MCP server for AI coding agents"
  homepage "https://github.com/dblock/excalc-rs"
  license "MIT"

  on_macos do
    on_arm do
      url "https://github.com/dblock/excalc-rs/releases/download/v0.3.4/excalc-0.3.4-aarch64-apple-darwin.tar.gz"
      sha256 "f2c5629afd4f7840d33c0cb4812c1f4fd49584cad6976e0412753e2a966ee8fa"
    end
    on_intel do
      url "https://github.com/dblock/excalc-rs/releases/download/v0.3.4/excalc-0.3.4-x86_64-apple-darwin.tar.gz"
      sha256 "f7d9d4a6b8ae7d86f1186fad86f914db5c587eba989e1f6f8bf20295ca843775"
    end
  end

  on_linux do
    on_arm do
      url "https://github.com/dblock/excalc-rs/releases/download/v0.3.4/excalc-0.3.4-aarch64-unknown-linux-musl.tar.gz"
      sha256 "9f12c15d791e04817f365183b3c7b6a2e136688d4afa191e0cb2bcee391c7e33"
    end
    on_intel do
      url "https://github.com/dblock/excalc-rs/releases/download/v0.3.4/excalc-0.3.4-x86_64-unknown-linux-musl.tar.gz"
      sha256 "2dcf9669a9656f9df72ae4c6035ea2f24ef6aeb48e656ca4c6b7d8a2bdbfd032"
    end
  end

  conflicts_with "calc", because: "both install a `calc` binary"

  def install
    bin.install "excalc", "calc", "excalc-mcp"
  end

  test do
    assert_equal "excalc #{version}", shell_output("#{bin}/excalc --version").strip
    assert_equal "4", shell_output("#{bin}/excalc '2 + 2'").strip
    assert_equal "4", shell_output("#{bin}/calc '2 + 2'").strip
    assert_path_exists bin/"excalc-mcp"
  end
end

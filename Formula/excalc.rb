# Generated from the latest dblock/excalc-rs release by bin/update-formula; do not edit.
class Excalc < Formula
  desc "Expression calculator CLI tool and MCP server for AI coding agents"
  homepage "https://github.com/dblock/excalc-rs"
  license "MIT"

  on_macos do
    on_arm do
      url "https://github.com/dblock/excalc-rs/releases/download/v0.3.3/excalc-0.3.3-aarch64-apple-darwin.tar.gz"
      sha256 "7e41eacfcbfcd26d3e0d3e1a48abd351f1e517689040ea2fecbffd0abd178d3a"
    end
    on_intel do
      url "https://github.com/dblock/excalc-rs/releases/download/v0.3.3/excalc-0.3.3-x86_64-apple-darwin.tar.gz"
      sha256 "144d8125736891290eaa84d44d788744f6407d63867c86dc06d8fcfb990f5912"
    end
  end

  on_linux do
    on_arm do
      url "https://github.com/dblock/excalc-rs/releases/download/v0.3.3/excalc-0.3.3-aarch64-unknown-linux-musl.tar.gz"
      sha256 "7a1ac3ce65a64e5483f2ef98a3b0fb3ebf19242ebcadcd5e4826fa84a6c392fb"
    end
    on_intel do
      url "https://github.com/dblock/excalc-rs/releases/download/v0.3.3/excalc-0.3.3-x86_64-unknown-linux-musl.tar.gz"
      sha256 "5ecf9c6fb61de580c522671ee7e90584fc7438645ca39ecde50d198b834363ad"
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

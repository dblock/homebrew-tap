# frozen_string_literal: true

require 'minitest/autorun'
require 'stringio'
require 'tmpdir'
require_relative '../lib/formula_updater'

class FormulaUpdaterTest < Minitest::Test
  TARGETS = %w[aarch64-apple-darwin x86_64-apple-darwin aarch64-unknown-linux-musl x86_64-unknown-linux-musl].freeze

  def setup
    @root = Dir.mktmpdir
    Dir.mkdir(File.join(@root, 'Formula'))
    @out = StringIO.new
    @err = StringIO.new
  end

  def teardown
    FileUtils.remove_entry(@root)
  end

  def digest(index)
    index.to_s * 64
  end

  def release(version = '1.2.3', targets: TARGETS)
    {
      'tag_name' => "v#{version}",
      'assets' => targets.map do |target|
        { 'name' => "fue-#{version}-#{target}.tar.gz.sha256", 'browser_download_url' => "https://example.com/#{target}.sha256" }
      end
    }
  end

  def fetcher(release, checksums: {})
    lambda do |url|
      if url == 'https://api.github.com/repos/dblock/fue-rs/releases/latest'
        release ? [200, JSON.generate(release)] : [404, '{}']
      else
        index = TARGETS.index(url[%r{example\.com/(.+)\.sha256}, 1])
        [200, checksums.fetch(index, "#{digest(index)}  fue-1.2.3-#{TARGETS[index]}.tar.gz\n")]
      end
    end
  end

  def run_updater(fetch, names = ['fue'])
    FormulaUpdater.run(names, fetch: fetch, root: @root, out: @out, err: @err)
  end

  def formula
    File.read(File.join(@root, 'Formula', 'fue.rb'))
  end

  def test_writes_a_formula_from_the_latest_release
    assert_equal 0, run_updater(fetcher(release))
    assert_equal "Updated fue to 1.2.3.\n", @out.string
    assert_includes formula, 'class Fue < Formula'
    refute_includes formula, 'version "', 'Homebrew reads the version from the archive name.'
    assert_includes formula, 'url "https://github.com/dblock/fue-rs/releases/download/v1.2.3/fue-1.2.3-aarch64-apple-darwin.tar.gz"'
    TARGETS.each_index { |index| assert_includes formula, "sha256 \"#{digest(index)}\"" }
    assert_includes formula, 'assert_equal "fue #{version}", shell_output("#{bin}/fue --version").strip'
  end

  def test_leaves_an_up_to_date_formula_alone
    run_updater(fetcher(release))
    @out.truncate(0)
    @out.rewind
    assert_equal 0, run_updater(fetcher(release), [])
    assert_equal "fue 1.2.3 is up to date.\n", @out.string
  end

  def test_waits_for_a_first_release
    assert_equal 0, run_updater(fetcher(nil))
    assert_equal "dblock/fue-rs has no releases yet.\n", @out.string
    refute File.exist?(File.join(@root, 'Formula', 'fue.rb'))
  end

  def test_requires_every_archive_checksum
    assert_equal 1, run_updater(fetcher(release(targets: TARGETS.first(3))))
    assert_equal "error: Release v1.2.3 has no fue-1.2.3-x86_64-unknown-linux-musl.tar.gz.sha256.\n", @err.string
  end

  def test_rejects_invalid_checksums
    assert_equal 1, run_updater(fetcher(release, checksums: { 1 => "not a checksum\n" }))
    assert_equal "error: fue-1.2.3-x86_64-apple-darwin.tar.gz.sha256 does not contain a SHA-256 checksum.\n", @err.string
  end

  def test_reports_failed_requests
    assert_equal 1, run_updater(->(_url) { [500, ''] })
    assert_equal "error: GitHub returned 500 for the latest release of dblock/fue-rs.\n", @err.string
    assert_equal 1, run_updater(lambda { |url| url.include?('api.github.com') ? [200, JSON.generate(release)] : [403, ''] })
    assert_includes @err.string, 'error: GitHub returned 403 for fue-1.2.3-aarch64-apple-darwin.tar.gz.sha256.'
  end

  def test_rejects_unknown_formulae
    assert_equal 1, run_updater(fetcher(release), ['nope'])
    assert_equal "error: Unknown formula `nope`.\n", @err.string
  end
end

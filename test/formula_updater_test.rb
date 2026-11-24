# frozen_string_literal: true

require_relative 'test_helper'
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

  def release(version = '1.2.3', targets: TARGETS, archive: 'fue')
    {
      'tag_name' => "v#{version}",
      'assets' => targets.map do |target|
        { 'name' => "#{archive}-#{version}-#{target}.tar.gz.sha256", 'browser_download_url' => "https://example.com/#{target}.sha256" }
      end
    }
  end

  def fetcher(release, checksums: {}, repository: 'dblock/fue-rs')
    lambda do |url|
      if url == "https://api.github.com/repos/#{repository}/releases/latest"
        release ? [200, JSON.generate(release)] : [404, '{}']
      elsif url.start_with?('https://api.github.com/')
        [404, '{}']
      else
        index = TARGETS.index(url[%r{example\.com/(.+)\.sha256}, 1])
        [200, checksums.fetch(index, "#{digest(index)}  archive-1.2.3-#{TARGETS[index]}.tar.gz\n")]
      end
    end
  end

  def run_updater(fetch, names = ['fue'])
    FormulaUpdater.run(names, fetch: fetch, root: @root, out: @out, err: @err)
  end

  def formula(name = 'fue')
    File.read(File.join(@root, 'Formula', "#{name}.rb"))
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

  def test_writes_a_formula_without_conflicts_or_extra_tests
    run_updater(fetcher(release))
    refute_includes formula, 'conflicts_with'
    assert_includes formula, "  bin.install \"fue\"\n  end"
    assert_includes formula, "--version\").strip\n  end"
  end

  def test_writes_a_formula_with_several_binaries_conflicts_and_extra_tests
    fetch = fetcher(release(archive: 'excalc'), repository: 'dblock/excalc-rs')
    assert_equal 0, run_updater(fetch, ['excalc'])
    assert_equal "Updated excalc to 1.2.3.\n", @out.string
    excalc = formula('excalc')
    assert_includes excalc, 'class Excalc < Formula'
    assert_includes excalc, 'url "https://github.com/dblock/excalc-rs/releases/download/v1.2.3/excalc-1.2.3-x86_64-apple-darwin.tar.gz"'
    assert_includes excalc, "  end\n\n  conflicts_with \"calc\", because: \"both install a `calc` binary\"\n\n  def install"
    assert_includes excalc, 'bin.install "excalc", "calc", "excalc-mcp"'
    assert_includes excalc, 'assert_equal "excalc #{version}", shell_output("#{bin}/excalc --version").strip'
    assert_includes excalc, %(assert_equal "4", shell_output("\#{bin}/calc '2 + 2'").strip)
    assert_includes excalc, "assert_path_exists bin/\"excalc-mcp\"\n  end"
  end

  def test_leaves_an_up_to_date_formula_alone
    run_updater(fetcher(release))
    @out.truncate(0)
    @out.rewind
    assert_equal 0, run_updater(fetcher(release), [])
    assert_equal "fue 1.2.3 is up to date.\ndblock/excalc-rs has no releases yet.\n", @out.string
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

  def response(klass, code, body: '', location: nil)
    response = klass.new('1.1', code, '')
    response['location'] = location if location
    response.instance_variable_set(:@body, body)
    response.instance_variable_set(:@read, true)
    response
  end

  # Stubs HTTP, recording each request and its host, and answering with `responses` in order.
  def with_http(responses, token: 'secret-token')
    requests = []
    start = lambda do |host, _port, **_options, &block|
      http = Object.new
      http.define_singleton_method(:request) do |request|
        requests << [host, request]
        responses.shift
      end
      block.call(http)
    end
    previous = ENV.fetch('GITHUB_TOKEN', nil)
    ENV['GITHUB_TOKEN'] = token
    Net::HTTP.stub(:start, start) { yield requests }
  ensure
    ENV['GITHUB_TOKEN'] = previous
  end

  def test_fetches_with_the_token_only_for_the_github_api
    with_http([response(Net::HTTPOK, '200', body: '{}')]) do |requests|
      assert_equal [200, '{}'], FormulaUpdater.fetch('https://api.github.com/repos/dblock/fue-rs/releases/latest')
      host, request = requests.first
      assert_equal 'api.github.com', host
      assert_equal 'Bearer secret-token', request['Authorization']
      assert_equal 'application/vnd.github+json', request['Accept']
    end
  end

  def test_follows_download_redirects_without_the_token
    responses = [
      response(Net::HTTPFound, '302', location: 'https://objects.example.com/fue.sha256'),
      response(Net::HTTPOK, '200', body: "#{digest(0)}  fue.tar.gz\n")
    ]
    with_http(responses) do |requests|
      status, body = FormulaUpdater.fetch('https://github.com/dblock/fue-rs/releases/download/v1.2.3/fue.sha256')
      assert_equal 200, status
      assert body.start_with?(digest(0))
      assert_equal %w[github.com objects.example.com], requests.map(&:first)
      assert(requests.none? { |_host, request| request['Authorization'] })
    end
  end

  def test_stops_following_redirects
    redirect = response(Net::HTTPFound, '302', location: 'https://github.com/loop')
    with_http([redirect, redirect]) do
      assert_equal [302, ''], FormulaUpdater.fetch('https://github.com/loop', redirects: 1)
    end
  end

  def test_omits_an_empty_token
    with_http([response(Net::HTTPOK, '200', body: '{}')], token: '') do |requests|
      FormulaUpdater.fetch('https://api.github.com/repos/dblock/fue-rs/releases/latest')
      assert_nil requests.first.last['Authorization']
    end
  end

  def test_rejects_unknown_formulae
    assert_equal 1, run_updater(fetcher(release), ['nope'])
    assert_equal "error: Unknown formula `nope`.\n", @err.string
  end
end

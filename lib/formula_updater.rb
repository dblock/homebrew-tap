# frozen_string_literal: true

require 'json'
require 'net/http'
require 'uri'

# Writes formulae in Formula/ from the latest GitHub release of each tool, using the archives and checksums attached to it.
module FormulaUpdater
  FORMULAE = {
    'fue' => {
      repository: 'dblock/fue-rs',
      class_name: 'Fue',
      desc: 'Find e-mail addresses of GitHub users and repository contributors',
      license: 'MIT',
      binary: 'fue',
      targets: {
        macos_arm: 'aarch64-apple-darwin',
        macos_intel: 'x86_64-apple-darwin',
        linux_arm: 'aarch64-unknown-linux-musl',
        linux_intel: 'x86_64-unknown-linux-musl'
      }
    }
  }.freeze

  class Error < StandardError; end

  module_function

  # Updates the named formulae, or all of them, and returns a process exit code.
  def run(names, fetch: method(:fetch), root: Dir.pwd, out: $stdout, err: $stderr)
    names = FORMULAE.keys if names.empty?
    names.each { |name| update(name, fetch: fetch, root: root, out: out) }
    0
  rescue Error => e
    err.puts "error: #{e.message}"
    1
  end

  def update(name, fetch:, root:, out:)
    config = FORMULAE.fetch(name) { raise Error, "Unknown formula `#{name}`." }
    release = latest_release(config[:repository], fetch)
    unless release
      out.puts "#{config[:repository]} has no releases yet."
      return
    end

    version = release.fetch('tag_name').delete_prefix('v')
    checksums = config[:targets].transform_values do |target|
      checksum(release, "#{config[:binary]}-#{version}-#{target}.tar.gz", fetch)
    end
    content = render(config, version, checksums)
    path = File.join(root, 'Formula', "#{name}.rb")
    if File.exist?(path) && File.read(path) == content
      out.puts "#{name} #{version} is up to date."
    else
      File.write(path, content)
      out.puts "Updated #{name} to #{version}."
    end
  end

  def latest_release(repository, fetch)
    status, body = fetch.call("https://api.github.com/repos/#{repository}/releases/latest")
    return if status == 404
    raise Error, "GitHub returned #{status} for the latest release of #{repository}." unless status == 200

    JSON.parse(body)
  end

  def checksum(release, archive, fetch)
    asset = release.fetch('assets').find { |candidate| candidate['name'] == "#{archive}.sha256" }
    raise Error, "Release #{release['tag_name']} has no #{archive}.sha256." unless asset

    status, body = fetch.call(asset.fetch('browser_download_url'))
    raise Error, "GitHub returned #{status} for #{archive}.sha256." unless status == 200

    digest = body.split.first.to_s
    raise Error, "#{archive}.sha256 does not contain a SHA-256 checksum." unless digest.match?(/\A\h{64}\z/)

    digest
  end

  def render(config, version, checksums)
    url = lambda do |target|
      "https://github.com/#{config[:repository]}/releases/download/v#{version}/" \
        "#{config[:binary]}-#{version}-#{config[:targets].fetch(target)}.tar.gz"
    end
    <<~RUBY
      # Generated from the latest #{config[:repository]} release by bin/update-formula; do not edit.
      class #{config[:class_name]} < Formula
        desc "#{config[:desc]}"
        homepage "https://github.com/#{config[:repository]}"
        license "#{config[:license]}"

        on_macos do
          on_arm do
            url "#{url.call(:macos_arm)}"
            sha256 "#{checksums.fetch(:macos_arm)}"
          end
          on_intel do
            url "#{url.call(:macos_intel)}"
            sha256 "#{checksums.fetch(:macos_intel)}"
          end
        end

        on_linux do
          on_arm do
            url "#{url.call(:linux_arm)}"
            sha256 "#{checksums.fetch(:linux_arm)}"
          end
          on_intel do
            url "#{url.call(:linux_intel)}"
            sha256 "#{checksums.fetch(:linux_intel)}"
          end
        end

        def install
          bin.install "#{config[:binary]}"
        end

        test do
          assert_equal "#{config[:binary]} \#{version}", shell_output("\#{bin}/#{config[:binary]} --version").strip
        end
      end
    RUBY
  end

  # Gets a URL, following redirects, with the GitHub token for the GitHub API.
  def fetch(url, redirects: 5)
    uri = URI(url)
    request = Net::HTTP::Get.new(uri)
    request['Accept'] = 'application/vnd.github+json' if uri.host == 'api.github.com'
    token = ENV.fetch('GITHUB_TOKEN', '')
    request['Authorization'] = "Bearer #{token}" if uri.host == 'api.github.com' && !token.empty?
    response = Net::HTTP.start(uri.host, uri.port, use_ssl: uri.scheme == 'https') { |http| http.request(request) }
    if response.is_a?(Net::HTTPRedirection) && redirects.positive?
      return fetch(URI.join(url, response['location']).to_s, redirects: redirects - 1)
    end

    [response.code.to_i, response.body]
  end
end

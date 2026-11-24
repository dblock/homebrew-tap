# frozen_string_literal: true

require 'simplecov'
require 'simplecov-lcov'

SimpleCov::Formatter::LcovFormatter.config do |config|
  config.report_with_single_file = true
  config.single_report_path = 'coverage/lcov.info'
end
SimpleCov.formatters = [SimpleCov::Formatter::HTMLFormatter, SimpleCov::Formatter::LcovFormatter]
SimpleCov.start do
  enable_coverage :branch
  add_filter '/test/'
end

require 'minitest/autorun'
require 'minitest/mock'

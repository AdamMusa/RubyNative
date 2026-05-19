# frozen_string_literal: true

require_relative "test_helper"

class RufletCliTemplatesTest < Minitest::Test
  def test_main_template_boots_app
    assert_includes Ruflet::CLI::MAIN_TEMPLATE, 'Ruflet.run do |page|'
    assert_includes Ruflet::CLI::MAIN_TEMPLATE, 'require "ruflet"'
  end

  def test_gemfile_template_includes_runtime_dependencies
    assert_includes Ruflet::CLI::GEMFILE_TEMPLATE, 'gem "ruflet_core"'
    assert_includes Ruflet::CLI::GEMFILE_TEMPLATE, 'gem "ruflet_server"'
    assert_includes Ruflet::CLI::GEMFILE_TEMPLATE, %(gem "ruflet", ">= #{Ruflet::VERSION}")
    assert_includes Ruflet::CLI::GEMFILE_TEMPLATE, %(gem "ruflet_core", ">= #{Ruflet::VERSION}")
    assert_includes Ruflet::CLI::GEMFILE_TEMPLATE, %(gem "ruflet_server", ">= #{Ruflet::VERSION}")
  end

  def test_main_template_uses_bootstrapped_app_title
    assert_includes format(Ruflet::CLI::MAIN_TEMPLATE, app_title: "Demo App"), 'page.title = "Demo App"'
  end
end

# frozen_string_literal: true

require_relative "test_helper"

class RufletRailsGemspecTest < Minitest::Test
  def test_gemspec_tracks_current_ruflet_packages
    gem_root = File.expand_path("..", __dir__)
    spec = Dir.chdir(gem_root) { Gem::Specification.load("ruflet_rails.gemspec") }

    assert_equal "0.0.7", spec.version.to_s
    assert_dependency spec, "ruflet_core", ">= 0.0.13"
    assert_dependency spec, "ruflet", ">= 0.0.13"
  end

  private

  def assert_dependency(spec, name, requirement)
    dependency = spec.dependencies.find { |item| item.name == name }

    refute_nil dependency, "Expected #{name} dependency"
    assert_equal requirement, dependency.requirement.to_s
  end
end

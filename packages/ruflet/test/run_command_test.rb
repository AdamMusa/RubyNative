# frozen_string_literal: true

require_relative "test_helper"
require "tmpdir"
require "fileutils"
require "rbconfig"

class RufletCliRunCommandTest < Minitest::Test
  class DummyRunner
    include Ruflet::CLI::RunCommand
  end

  def test_find_nearest_gemfile_walks_up_directories
    Dir.mktmpdir do |dir|
      root = File.join(dir, "repo")
      nested = File.join(root, "examples", "ruflet_studio")
      FileUtils.mkdir_p(nested)
      gemfile = File.join(root, "Gemfile")
      File.write(gemfile, "source \"https://rubygems.org\"\n")

      found = DummyRunner.new.send(:find_nearest_gemfile, nested)
      assert_equal gemfile, found
    end
  end

  def test_find_nearest_gemfile_returns_nil_without_gemfile
    Dir.mktmpdir do |dir|
      nested = File.join(dir, "a", "b")
      FileUtils.mkdir_p(nested)
      found = DummyRunner.new.send(:find_nearest_gemfile, nested)
      assert_nil found
    end
  end

  def test_release_asset_matches_supports_fallback_names
    runner = DummyRunner.new

    assert runner.send(:release_asset_matches?, "ruflet_client-web-build.tar.gz", :web, nil)
    assert runner.send(:release_asset_matches?, "ruflet_client-macos-arm64.zip", :desktop, "macos")
    assert runner.send(:release_asset_matches?, "ruflet_client-linux-amd64.tgz", :desktop, "linux")
    assert runner.send(:release_asset_matches?, "ruflet_client-windows-latest.zip", :desktop, "windows")

    refute runner.send(:release_asset_matches?, "other_project-web.tar.gz", :web, nil)
    refute runner.send(:release_asset_matches?, "ruflet_client-macos.tar.gz", :desktop, "macos")
  end

  def test_prebuilt_macos_desktop_presence_repairs_missing_file_picker_entitlement
    runner = DummyRunner.new

    Dir.mktmpdir do |dir|
      app_dir = File.join(dir, "desktop", "ruflet_client.app")
      bin = File.join(app_dir, "Contents", "MacOS", "ruflet_client")
      FileUtils.mkdir_p(File.dirname(bin))
      File.write(bin, "#!/bin/sh\n")
      FileUtils.chmod("+x", bin)

      checks = [false, true]
      calls = []
      runner.define_singleton_method(:host_platform_name) { "macos" }
      runner.define_singleton_method(:macos_app_has_file_picker_entitlement?) { |_path| checks.shift }
      runner.define_singleton_method(:system) do |*args, **_kwargs|
        calls << args
        true
      end

      assert runner.send(:prebuilt_desktop_present?, dir, platform: "macos")
      assert_equal "/usr/bin/codesign", calls.first[0]
      assert_includes calls.first, "--entitlements"
      assert_includes calls.first, app_dir
    end
  end

  def test_build_runtime_command_without_gemfile_runs_script_directly
    runner = DummyRunner.new
    env = {}

    cmd = runner.send(:build_runtime_command, "/tmp/app.rb", gemfile_path: nil, env: env)

    assert_equal [RbConfig.ruby, "/tmp/app.rb"], cmd
  end

  def test_build_runtime_command_with_gemfile_uses_bundler_setup
    runner = DummyRunner.new
    Dir.mktmpdir do |dir|
      gemfile = File.join(dir, "Gemfile")
      File.write(gemfile, "source \"https://rubygems.org\"\n")
      env = {}
      runner.define_singleton_method(:system) { |_env, *_args| true }

      cmd = runner.send(:build_runtime_command, "/tmp/app.rb", gemfile_path: gemfile, env: env)
      assert_equal "ruby", File.basename(cmd[0])
      assert_equal "-rbundler/setup", cmd[1]
      assert_equal "/tmp/app.rb", cmd[2]
    end
  end

  def test_project_run_requires_managed_client_for_extension_services
    runner = DummyRunner.new

    Dir.mktmpdir do |dir|
      File.write(File.join(dir, "ruflet.yaml"), <<~YAML)
        services:
          - map
          - audio-recorder
      YAML

      Dir.chdir(dir) do
        assert runner.send(:project_run_requires_managed_client?)
      end
    end
  end

  def test_project_run_does_not_require_managed_client_without_extensions
    runner = DummyRunner.new

    Dir.mktmpdir do |dir|
      File.write(File.join(dir, "ruflet.yaml"), <<~YAML)
        services:
          - unknown_service
      YAML

      Dir.chdir(dir) do
        refute runner.send(:project_run_requires_managed_client?)
      end
    end
  end

  def test_project_desktop_client_command_prepares_extension_client
    runner = DummyRunner.new

    Dir.mktmpdir do |dir|
      client_dir = File.join(dir, "build", "client")
      FileUtils.mkdir_p(client_dir)
      File.write(File.join(dir, "ruflet.yaml"), <<~YAML)
        services:
          - map
      YAML

      prepare_calls = []
      flutter_calls = []
      runner.define_singleton_method(:host_platform_name) { "macos" }
      runner.define_singleton_method(:ensure_ruflet_build_assets) { |verbose:| verbose == false }
      runner.define_singleton_method(:ensure_flutter_client_dir) { |verbose:| verbose == false ? client_dir : nil }
      runner.define_singleton_method(:ensure_flutter!) do |purpose, client_dir:|
        flutter_calls << { purpose: purpose, client_dir: client_dir }
        { env: { "PATH" => "/bin" }, flutter: "/fake/flutter" }
      end
      runner.define_singleton_method(:build_tool_env) do |env, platform, path|
        env.merge("RUFLET_PLATFORM" => platform, "RUFLET_CLIENT_DIR" => path)
      end
      runner.define_singleton_method(:prepare_flutter_client) do |path, platform:, tools:, config:, self_contained:, verbose:|
        prepare_calls << {
          path: path,
          platform: platform,
          tools: tools,
          config: config,
          self_contained: self_contained,
          verbose: verbose
        }
        true
      end

      Dir.chdir(dir) do
        cmd = runner.send(:detect_project_desktop_client_command, "http://localhost:8550")

        assert_equal [{ purpose: "run", client_dir: client_dir }], flutter_calls
        assert_equal 1, prepare_calls.length
        assert_equal ["map"], prepare_calls.first[:config]["services"]
        assert_equal false, prepare_calls.first[:self_contained]
        assert_equal false, prepare_calls.first[:verbose]
        assert_equal "macos", prepare_calls.first[:platform]
        assert_equal client_dir, prepare_calls.first[:path]
        assert_equal(
          [
            { "PATH" => "/bin", "RUFLET_PLATFORM" => "macos", "RUFLET_CLIENT_DIR" => client_dir },
            "/fake/flutter",
            "run",
            "-d",
            "macos",
            "--target",
            "lib/main.server.dart",
            "--dart-define",
            "RUFLET_BACKEND_URL=http://localhost:8550"
          ],
          cmd
        )
      end
    end
  end

end

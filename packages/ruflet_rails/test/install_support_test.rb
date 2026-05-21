# frozen_string_literal: true

require_relative "test_helper"
require "fileutils"

class InstallSupportTest < Minitest::Test
  def test_default_ruflet_yaml_contains_rails_config_and_assets
    yaml = Ruflet::Rails::InstallSupport.default_ruflet_yaml(app_name: "Demo")

    assert_includes yaml, "name: Demo"
    assert_includes yaml, "icon_launcher: assets/icon.png"
    assert_includes yaml, "services: []"
    refute_includes yaml, "rails:"
    refute_includes yaml, "dir: assets"
  end

  def test_route_snippet_matches_mobile_mount
    route = Ruflet::Rails::InstallSupport.route_snippet(
      entrypoint: "app/mobile/main.rb",
      mount_path: "/ws"
    )

    assert_equal 'mount Ruflet::Rails.mobile(Rails.root.join("app/mobile/main.rb")), at: "/ws"', route
  end

  def test_mobile_app_template_uses_ruflet_run
    template = Ruflet::Rails::InstallSupport.default_mobile_app_template(app_title: "Demo")

    assert_includes template, 'Ruflet.run do |page|'
    assert_includes template, 'page.title = "Demo"'
    assert_includes template, "floating_action_button: fab("
  end

  def test_configure_ruflet_client_applies_audio_recorder_native_permissions
    Dir.mktmpdir do |dir|
      make_client_native_files(dir)
      File.write(File.join(dir, "ruflet.yaml"), "services:\n  - audio_recorder\n")

      Ruflet::Rails::InstallSupport.configure_ruflet_client(dir)

      client_dir = File.join(dir, "ruflet_client")
      assert_includes File.read(File.join(client_dir, "android", "app", "src", "main", "AndroidManifest.xml")), "android.permission.RECORD_AUDIO"
      assert_includes File.read(File.join(client_dir, "ios", "Runner", "Info.plist")), "NSMicrophoneUsageDescription"
      assert_includes File.read(File.join(client_dir, "macos", "Runner", "Info.plist")), "NSMicrophoneUsageDescription"
      assert_includes File.read(File.join(client_dir, "macos", "Runner", "DebugProfile.entitlements")), "com.apple.security.device.audio-input"
      assert_includes File.read(File.join(client_dir, "macos", "Runner", "Release.entitlements")), "com.apple.security.device.audio-input"
    end
  end

  private

  def make_client_native_files(root)
    client_dir = File.join(root, "ruflet_client")
    FileUtils.mkdir_p(File.join(client_dir, "android", "app", "src", "main"))
    FileUtils.mkdir_p(File.join(client_dir, "ios", "Runner"))
    FileUtils.mkdir_p(File.join(client_dir, "macos", "Runner"))
    File.write(File.join(client_dir, "pubspec.yaml"), "name: demo\n")
    File.write(File.join(client_dir, "android", "app", "src", "main", "AndroidManifest.xml"), <<~XML)
      <manifest xmlns:android="http://schemas.android.com/apk/res/android">
          <application android:label="Demo"/>
      </manifest>
    XML
    File.write(File.join(client_dir, "ios", "Runner", "Info.plist"), minimal_plist)
    File.write(File.join(client_dir, "macos", "Runner", "Info.plist"), minimal_plist)
    %w[DebugProfile Release].each do |name|
      File.write(File.join(client_dir, "macos", "Runner", "#{name}.entitlements"), minimal_plist)
    end
  end

  def minimal_plist
    <<~PLIST
      <?xml version="1.0" encoding="UTF-8"?>
      <!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
      <plist version="1.0">
      <dict>
      </dict>
      </plist>
    PLIST
  end
end

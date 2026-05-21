# frozen_string_literal: true

require "fileutils"
require "yaml"

module Ruflet
  module Rails
    module InstallSupport
      CLIENT_EXTENSION_MAP = {
        "ads" => { package: "flet_ads", alias: "ruflet_ads" },
        "audio" => { package: "flet_audio", alias: "ruflet_audio" },
        "audio_recorder" => { package: "flet_audio_recorder", alias: "ruflet_audio_recorder" },
        "camera" => { package: "flet_camera", alias: "ruflet_camera" },
        "charts" => { package: "flet_charts", alias: "ruflet_charts" },
        "code_editor" => { package: "flet_code_editor", alias: "ruflet_code_editor" },
        "color_pickers" => { package: "flet_color_pickers", alias: "ruflet_color_picker" },
        "datatable2" => { package: "flet_datatable2", alias: "ruflet_datatable2" },
        "flashlight" => { package: "flet_flashlight", alias: "ruflet_flashlight" },
        "geolocator" => { package: "flet_geolocator", alias: "ruflet_geolocator" },
        "lottie" => { package: "flet_lottie", alias: "ruflet_lottie" },
        "map" => { package: "flet_map", alias: "ruflet_map" },
        "permission_handler" => { package: "flet_permission_handler", alias: "ruflet_permission_handler" },
        "secure_storage" => { package: "flet_secure_storage", alias: "ruflet_secure_storage" },
        "video" => { package: "flet_video", alias: "ruflet_video" },
        "webview" => { package: "flet_webview", alias: "ruflet_webview" }
      }.freeze

      SERVICE_NATIVE_REQUIREMENTS = {
        "audio_recorder" => {
          android_permissions: ["android.permission.RECORD_AUDIO"],
          ios_info: {
            "NSMicrophoneUsageDescription" => "Microphone access is required for audio recording."
          },
          macos_info: {
            "NSMicrophoneUsageDescription" => "Microphone access is required for audio recording."
          },
          macos_entitlements: {
            "com.apple.security.device.audio-input" => true
          }
        },
        "barometer" => {
          ios_info: {
            "NSMotionUsageDescription" => "Motion access is required for barometer readings."
          }
        }
      }.freeze

      module_function

      def default_mobile_app_template(app_title:)
        <<~RUBY
          require "ruflet"

          Ruflet.run do |page|
            page.title = #{app_title.inspect}
            count = 0
            count_text = text(count.to_s, size: 40)

            page.add(
              container(
                expand: true,
                alignment: Ruflet::MainAxisAlignment::CENTER,
                content: column(
                  alignment: Ruflet::MainAxisAlignment::CENTER,
                  horizontal_alignment: Ruflet::CrossAxisAlignment::CENTER,
                  children: [
                    text("You have pushed the button this many times:"),
                    count_text
                  ]
                )
              ),
              floating_action_button: fab(
                icon: Ruflet::MaterialIcons::ADD,
                on_click: ->(_e) do
                  count += 1
                  page.update(count_text, value: count.to_s)
                end
              )
            )
          end
        RUBY
      end

      def default_ruflet_yaml(app_name:)
        <<~YAML
          app:
            name: #{app_name}
            ruflet_client_url: ""

          services: []

          assets:
            splash_screen: assets/splash.png
            icon_launcher: assets/icon.png
        YAML
      end

      def route_snippet(entrypoint: "app/mobile/main.rb", mount_path: "/ws")
        %(mount Ruflet::Rails.mobile(Rails.root.join("#{entrypoint}")), at: "#{mount_path}")
      end

      def client_template_root
        env = ENV["RUFLET_CLIENT_TEMPLATE_DIR"].to_s.strip
        return env if !env.empty? && Dir.exist?(env)

        candidates = [
          File.expand_path("../../../../../ruflet_client", __dir__),
          File.expand_path("../../../../../templates/ruflet_flutter_template", __dir__)
        ]
        candidates.find { |path| Dir.exist?(path) }
      end

      def copy_ruflet_client_template(root)
        template_root = client_template_root
        return false unless template_root

        target = File.join(root, "ruflet_client")
        return true if Dir.exist?(target)

        FileUtils.cp_r(template_root, target)
        prune_client_template(target)
        true
      end

      def prune_client_template(target)
        %w[
          .dart_tool
          .idea
          build
          ios/Pods
          ios/.symlinks
          ios/Podfile.lock
          macos/Pods
          macos/Podfile.lock
          android/.gradle
          android/.kotlin
          android/local.properties
        ].each do |path|
          full = File.join(target, path)
          FileUtils.rm_rf(full) if File.exist?(full)
        end
      end

      def configure_ruflet_client(root)
        config_path = File.join(root, "ruflet.yaml")
        return unless File.file?(config_path)

        config = YAML.safe_load(File.read(config_path), aliases: true) || {}
        extension_keys = Array(config["services"]).map { |v| normalize_extension_key(v) }.compact.uniq
        extension_packages = extension_keys.filter_map { |key| CLIENT_EXTENSION_MAP[key]&.fetch(:package) }.uniq
        extension_aliases = extension_keys.filter_map { |key| CLIENT_EXTENSION_MAP[key]&.fetch(:alias) }.uniq

        client_dir = File.join(root, "ruflet_client")
        return unless Dir.exist?(client_dir)

        prune_client_pubspec(File.join(client_dir, "pubspec.yaml"), extension_packages)
        prune_client_main(File.join(client_dir, "lib", "main.dart"), extension_aliases)
        apply_service_native_requirements(client_dir, extension_keys)
      end

      def normalize_extension_key(value)
        key = value.to_s.strip.downcase
        return nil if key.empty?

        key.tr!("-", "_")
        key.gsub!(/\A(flet_)+/, "")
        key.gsub!(/\Aservice_/, "")
        key.gsub!(/\Acontrol_/, "")
        key = "file_picker" if key == "filepicker"
        key
      end

      def prune_client_pubspec(path, selected_packages)
        return unless File.file?(path)

        data = YAML.safe_load(File.read(path), aliases: true) || {}
        deps = (data["dependencies"] || {}).dup
        deps.keys.each do |name|
          next unless name.start_with?("flet_")
          next if name == "flet"
          next if selected_packages.include?(name)

          deps.delete(name)
        end
        data["dependencies"] = deps
        File.write(path, YAML.dump(data))
      end

      def prune_client_main(path, selected_aliases)
        return unless File.file?(path)

        lines = File.readlines(path)
        alias_to_package = {}

        lines.each do |line|
          match = line.match(%r{\Aimport 'package:(flet_[^/]+)/\1\.dart' as ([a-zA-Z0-9_]+);})
          alias_to_package[match[2]] = match[1] if match
        end

        kept = lines.select do |line|
          import_match = line.match(%r{\Aimport 'package:(flet_[^/]+)/\1\.dart' as ([a-zA-Z0-9_]+);})
          if import_match
            package_name = import_match[1]
            next true if package_name == "flet"
            next true if selected_aliases.include?(import_match[2])
            next false
          end

          extension_match = line.match(/\A\s*([a-zA-Z0-9_]+)\.Extension\(\),\s*\z/)
          if extension_match
            extension_alias = extension_match[1]
            package_name = alias_to_package[extension_alias]
            next true if package_name.nil?
            next true if selected_aliases.include?(extension_alias)
            next false
          end

          true
        end

        File.write(path, kept.join)
      end

      def apply_service_native_requirements(client_dir, extension_keys)
        stale_keys = SERVICE_NATIVE_REQUIREMENTS.keys - extension_keys
        remove_service_native_requirements(client_dir, stale_keys)

        requirements = merge_service_native_requirements(extension_keys)
        return if requirements.empty?

        android_manifest = File.join(client_dir, "android", "app", "src", "main", "AndroidManifest.xml")
        Array(requirements[:android_permissions]).each do |permission|
          ensure_android_permission(android_manifest, permission)
        end

        ios_info = File.join(client_dir, "ios", "Runner", "Info.plist")
        Hash(requirements[:ios_info]).each do |key, value|
          ensure_plist_string(ios_info, key, value)
        end

        macos_info = File.join(client_dir, "macos", "Runner", "Info.plist")
        Hash(requirements[:macos_info]).each do |key, value|
          ensure_plist_string(macos_info, key, value)
        end

        %w[DebugProfile Release].each do |name|
          entitlements_path = File.join(client_dir, "macos", "Runner", "#{name}.entitlements")
          Hash(requirements[:macos_entitlements]).each do |key, value|
            ensure_plist_boolean(entitlements_path, key, value)
          end
        end
      end

      def remove_service_native_requirements(client_dir, extension_keys)
        requirements = merge_service_native_requirements(extension_keys)
        return if requirements.empty?

        android_manifest = File.join(client_dir, "android", "app", "src", "main", "AndroidManifest.xml")
        Array(requirements[:android_permissions]).each do |permission|
          remove_android_permission(android_manifest, permission)
        end

        [File.join(client_dir, "ios", "Runner", "Info.plist"), File.join(client_dir, "macos", "Runner", "Info.plist")].each do |path|
          (Hash(requirements[:ios_info]).keys + Hash(requirements[:macos_info]).keys).uniq.each do |key|
            remove_plist_entry(path, key)
          end
        end

        %w[DebugProfile Release].each do |name|
          entitlements_path = File.join(client_dir, "macos", "Runner", "#{name}.entitlements")
          Hash(requirements[:macos_entitlements]).each_key do |key|
            remove_plist_entry(entitlements_path, key)
          end
        end
      end

      def merge_service_native_requirements(extension_keys)
        extension_keys.each_with_object({}) do |key, memo|
          requirements = SERVICE_NATIVE_REQUIREMENTS[key]
          next unless requirements

          memo[:android_permissions] ||= []
          memo[:android_permissions] |= Array(requirements[:android_permissions])
          %i[ios_info macos_info macos_entitlements].each do |section|
            memo[section] ||= {}
            memo[section].merge!(requirements[section] || {})
          end
        end
      end

      def ensure_android_permission(path, permission)
        return unless File.file?(path)

        content = File.read(path)
        return if content.include?(permission)

        permission_line = %(    <uses-permission android:name="#{xml_escape(permission)}"/>\n)
        updated = content.sub(/(<manifest\b[^>]*>\s*)/m) { "#{Regexp.last_match(1)}#{permission_line}" }
        File.write(path, updated == content ? "#{permission_line}#{content}" : updated)
      end

      def remove_android_permission(path, permission)
        return unless File.file?(path)

        content = File.read(path)
        updated = content.gsub(%r{^\s*<uses-permission\s+android:name="#{Regexp.escape(permission)}"\s*/>\s*\n?}, "")
        File.write(path, updated) unless updated == content
      end

      def ensure_plist_string(path, key, value)
        ensure_plist_entry(path, key, "<string>#{xml_escape(value)}</string>")
      end

      def ensure_plist_boolean(path, key, value)
        ensure_plist_entry(path, key, value ? "<true/>" : "<false/>")
      end

      def ensure_plist_entry(path, key, value_xml)
        return unless File.file?(path)

        content = File.read(path)
        return if content.include?("<key>#{key}</key>")

        entry = "\t<key>#{key}</key>\n\t#{value_xml}\n"
        updated = content.sub(%r{</dict>}, "#{entry}</dict>")
        File.write(path, updated == content ? "#{content}\n#{entry}" : updated)
      end

      def remove_plist_entry(path, key)
        return unless File.file?(path)

        content = File.read(path)
        updated = content.gsub(%r{\s*<key>#{Regexp.escape(key)}</key>\s*<(?:string>.*?</string|true/|false/)>\s*}m, "\n")
        File.write(path, updated) unless updated == content
      end

      def xml_escape(value)
        value.to_s
             .gsub("&", "&amp;")
             .gsub("<", "&lt;")
             .gsub(">", "&gt;")
             .gsub('"', "&quot;")
             .gsub("'", "&apos;")
      end
    end
  end
end
